require 'fileutils'
require 'tmpdir'

require 'TerraformDevKit/terragrunt_installer'

RSpec.describe TerraformDevKit::TerragruntInstaller do
  describe '#installed_terragrunt_version' do
    context 'terragrunt is not installed' do
      before(:example) do
        allow(TerraformDevKit::Command)
          .to receive(:run)
          .and_throw('Error running command')
      end

      it 'returns nil' do
        version = TerraformDevKit::TerragruntInstaller.installed_terragrunt_version
        expect(version).to be_nil
      end
    end

    context 'terragrunt is installed' do
      before(:example) do
        allow(TerraformDevKit::Command)
          .to receive(:run)
          .and_return("terragrunt version v0.12.20\r\n")
      end

      it 'returns the version' do
        version = TerraformDevKit::TerragruntInstaller.installed_terragrunt_version
        expect(version).to eq('0.12.20')
      end
    end
  end

  describe '#install_local' do
    before(:example) do
      allow(TerraformDevKit::Command)
        .to receive(:run)
        .and_throw('Error running command')

      @tmpdir = Dir.mktmpdir
    end

    after(:example) do
      FileUtils.rm_rf(@tmpdir, secure: true)
    end

    it 'returns nil' do
      Dir.chdir(@tmpdir) do
        TerraformDevKit::TerragruntInstaller.install_local('0.12.20')

        allow(TerraformDevKit::Command)
          .to receive(:run)
          .and_call_original

        result = TerraformDevKit::Command.run('./terragrunt --version')
        match = /terragrunt version v(\d+\.\d+\.\d+)/.match(result)
        version = match[1] unless match.nil?

        expect(version).to eq('0.12.20')
      end
    end
  end
end
