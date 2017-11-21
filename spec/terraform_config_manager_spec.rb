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
        project_name = "{{ProjectName}}"
        project_acronym = "{{ProjectAcronym}}"
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
        project_name = "some-project"
        project_acronym = "SP"
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
            project-name: some project
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
      project = double(name: 'some-project', acronym: 'SP')
      TDK::TerraformConfigManager.register_extra_vars_proc(
        proc { { Dummy: 'foobar' } }
      )
      TDK::TerraformConfigManager.setup(env, project)

      expect(File.read('envs/dev/test.tf')).to eq(tf_output)
      expect(File.read('envs/dev/test.tfvars')).to eq(tfvars_output)
    end
  end
end
