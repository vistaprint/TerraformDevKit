require 'tmpdir'

require 'TerraformDevKit/config'
require 'TerraformDevKit/environment'
require 'TerraformDevKit/terraform_template_renderer'

TDK = TerraformDevKit

RSpec.describe TDK::TerraformTemplateRenderer do
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

  let(:json_template) do
    %({
        "env": "{{Environment}}"
      })
  end

  let(:json_output) do
    %({
        "env": "dev"
      })
  end

  before(:example) do
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir) do
      File.open('test.tf.mustache', 'w') { |f| f.write(tf_template) }
      FileUtils.makedirs('foo')
      File.open('foo/bar.json.mustache', 'w') { |f| f.write(json_template) }
      File.open('config.yml', 'w') do |f|
        f.write(
          %(
            aws:
              profile: dummyprofile
              region: dummyregion
            project-name: some project
            template-dirs:
              foo: foo
          )
        )
      end
    end
  end

  after(:example) do
    FileUtils.rm_rf(@tmpdir, secure: true)
  end

  it 'creates configuration files' do
    # TODO: get rid of ROOT_PATH
    ROOT_PATH = @tmpdir
    Dir.chdir(@tmpdir) do
      # TODO: find a way to make Configuration not a singleton
      TDK::Configuration.init('config.yml')

      env = TDK::Environment.new('dev')
      project = double(name: 'some-project', acronym: 'SP')

      FileUtils.makedirs(env.working_dir)

      TDK::TerraformTemplateRenderer
        .new(env, project, proc { { Dummy: 'foobar' } })
        .render_files

      expect(File.read('envs/dev/test.tf')).to eq(tf_output)
      expect(File.read('envs/dev/foo/bar.json')).to eq(json_output)
    end
  end  
end
