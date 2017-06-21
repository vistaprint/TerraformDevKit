require 'fileutils'
require 'tmpdir'

require 'TerraformDevKit/os'
require 'TerraformDevKit/terraform_env_manager'
require 'TerraformDevKit/terraform_installer'

TerraformEnvManager = TerraformDevKit::TerraformEnvManager

RSpec.describe TerraformEnvManager do
  AN_ENVIRONMENT = 'an-environment'.freeze

  before(:all) do
    @saved_env_path = ENV['PATH']
    @terraform_dir = Dir.mktmpdir

    Dir.chdir(@terraform_dir) do
      TerraformDevKit::TerraformInstaller.install_local('0.9.8')
      ENV['PATH'] = TerraformDevKit::OS.join_env_path(
        TerraformDevKit::OS.convert_to_local_path(Dir.pwd),
        ENV['PATH']
      )
    end
  end

  after(:all) do
    ENV['PATH'] = @saved_env_path
    FileUtils.rm_rf(@terraform_dir, secure: true)
  end

  before(:example) do
    @pwd = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
  end

  after(:example) do
    Dir.chdir(@pwd)
    FileUtils.rm_rf(@tmpdir, secure: true)
  end

  describe '#exist?' do
    it 'detects whether an environment exists' do
      expect(TerraformEnvManager.exist?('default')).to be true
      expect(TerraformEnvManager.exist?('non-existing')).to be false
    end
  end

  describe '#create' do
    it 'creates an environment' do
      expect(TerraformEnvManager.exist?(AN_ENVIRONMENT)).to be false
      TerraformEnvManager.create(AN_ENVIRONMENT)
      expect(TerraformEnvManager.exist?(AN_ENVIRONMENT)).to be true
    end
  end

  describe '#delete' do
    it 'deletes an environment' do
      if TerraformDevKit::OS.host_os == 'windows'
        # TODO: Get rid of this hack once the following issue gets fixed:
        # https://github.com/hashicorp/terraform/issues/15343
        puts 'Skipping #delete test as it is not supported in Windows'
      else
        TerraformEnvManager.create(AN_ENVIRONMENT)
        expect(TerraformEnvManager.exist?(AN_ENVIRONMENT)).to be true

        TerraformEnvManager.delete(AN_ENVIRONMENT)
        expect(TerraformEnvManager.exist?(AN_ENVIRONMENT)).to be false
      end
    end
  end

  describe '#select' do
    it 'selects the given environment' do
      TerraformEnvManager.create(AN_ENVIRONMENT)
      expect(TerraformEnvManager.active).to eq(AN_ENVIRONMENT)

      TerraformEnvManager.select('default')
      expect(TerraformEnvManager.active).to eq('default')
    end
  end

  describe '#active' do
    it 'returns default when no other environment exists' do
      expect(TerraformEnvManager.active).to eq('default')
    end

    it 'returns the active environment' do
      TerraformEnvManager.create(AN_ENVIRONMENT)
      expect(TerraformEnvManager.active).to eq(AN_ENVIRONMENT)
    end
  end
end
