require 'TerraformDevKit/config'
require 'TerraformDevKit/environment'
require 'TerraformDevKit/terraform_config_manager'

require 'fileutils'
require 'tmpdir'

TDK = TerraformDevKit

RSpec.describe TDK::TerraformConfigManager do
  let(:tf_template) do
    %(
      provider "aws" {
        profile = "${var.profile}"
        region  = "${var.region}"
      }

      locals {
        env = "{{Environment}}"
        dummy = "{{Dummy}}"
      }
    )
  end

  let(:tf_output) do
    %(
      provider "aws" {
        profile = "${var.profile}"
        region  = "${var.region}"
      }

      locals {
        env = "dev"
        dummy = "foobar"
      }
    )
  end

  let(:tfvars_template) do
    %(
      profile = "{{Profile}}"
      region  = "{{Region}}"
    )
  end

  let(:tfvars_output) do
    %(
      profile = "dummyprofile"
      region  = "dummyregion"
    )
  end

  before(:example) do
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir) do
      File.open('test.tf.mustache', 'w')     { |f| f.write(tf_template) }
      File.open('test.tfvars.mustache', 'w') { |f| f.write(tfvars_template) }
      File.open('config.yml', 'w') do |f|
        f.write(
          %(
            aws:
              profile: dummyprofile
              region: dummyregion
          )
        )
      end
    end
  end

  after(:example) do
    FileUtils.rm_rf(@tmpdir, secure: true)
  end

  it 'creates configuration files' do
    Dir.chdir(@tmpdir) do
      # TODO: find a way to make Configuration not a singleton
      TDK::Configuration.init('config.yml')
      env = TDK::Environment.new('dev')
      TDK::TerraformConfigManager.register_extra_vars_proc(
        proc { { Dummy: 'foobar' } }
      )
      TDK::TerraformConfigManager.setup(env)

      expect(File.read('envs/dev/test.tf')).to eq(tf_output)
      expect(File.read('envs/dev/test.tfvars')).to eq(tfvars_output)
    end
  end

  describe '#update_modules?' do
    before(:example) do
      @saved_env_var = ENV['TF_DEVKIT_UPDATE_MODULES']
    end

    after(:example) do
      if @saved_env_var.nil?
        ENV.delete('TF_DEVKIT_UPDATE_MODULES')
      else
        ENV['TF_DEVKIT_UPDATE_MODULES'] = @saved_env_var
      end
    end

    context 'env var is not set' do
      it 'returns false' do
        expect(TDK::TerraformConfigManager.update_modules?).to be false
      end
    end

    context 'env var is set' do
      [
        { value: 'true',  expected: true },
        { value: 'false', expected: false },
        { value: 'foo',   expected: false }
      ].each do |example|
        it 'updates modules only if env var is true' do
          ENV['TF_DEVKIT_UPDATE_MODULES'] = example[:value]
          expect(TDK::TerraformConfigManager.update_modules?)
            .to eq(example[:expected])
        end
      end
    end
  end
end
