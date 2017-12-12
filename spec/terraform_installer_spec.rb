require 'fileutils'
require 'tmpdir'

require 'TerraformDevKit/terraform_installer'

TDK = TerraformDevKit

RSpec.describe TDK::TerraformInstaller do
  describe '#installed_terraform_version' do
    context 'terraform is not installed' do
      before(:example) do
        allow(TDK::Command)
          .to receive(:run)
          .and_throw('Error running command')
      end

      it 'returns nil' do
        version = TDK::TerraformInstaller.installed_terraform_version
        expect(version).to be_nil
      end
    end

    context 'terraform is installed' do
      before(:example) do
        allow(TDK::Command)
          .to receive(:run)
          .and_return(['Terraform v0.11.1'])
      end

      it 'returns the version' do
        version = TDK::TerraformInstaller.installed_terraform_version
        expect(version).to eq('0.11.1')
      end
    end
  end

  describe '#extract_version' do
    context 'empty output' do
      it 'returns nil' do
        version = TDK::TerraformInstaller.extract_version([])
        expect(version).to be_nil
      end
    end

    context 'version is missing' do
      it 'returns nil' do
        version = TDK::TerraformInstaller.extract_version(%w[foo bar])
        expect(version).to be_nil
      end
    end

    context 'version is present' do
      [
        { output: ['Terraform v0.11.1'], version: '0.11.1' },
        { output: ['foo', 'Terraform v0.11.1', 'bar'], version: '0.11.1' },
        { output: ['Terraform v11.22.33'], version: '11.22.33' }
      ].each do |example|
        it 'returns the version' do
          version = TDK::TerraformInstaller.extract_version(example[:output])
          expect(version).to eq(example[:version])
        end
      end
    end

    context 'version is present more than once' do
      it 'returns nil' do
        output = [
          'Terraform v0.11.1',
          'Terraform v0.11.1'
        ]
        version = TDK::TerraformInstaller.extract_version(output)
        expect(version).to be_nil
      end
    end
  end

  describe '#install_local' do
    before(:example) do
      allow(TDK::Command)
        .to receive(:run)
        .and_throw('Error running command')

      @tmpdir = Dir.mktmpdir
    end

    after(:example) do
      FileUtils.rm_rf(@tmpdir, secure: true)
    end

    it 'returns nil' do
      Dir.chdir(@tmpdir) do
        TDK::TerraformInstaller.install_local(
          '0.11.1',
          directory: 'bin'
        )

        allow(TDK::Command)
          .to receive(:run)
          .and_call_original

        output = TDK::Command.run('./bin/terraform --version')
        version = TDK::TerraformInstaller.extract_version(output)
        expect(version).to eq('0.11.1')
      end
    end
  end
end
