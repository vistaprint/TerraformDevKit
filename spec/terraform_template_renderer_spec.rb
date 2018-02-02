require 'tmpdir'

require 'TerraformDevKit/config'
require 'TerraformDevKit/environment'
require 'TerraformDevKit/terraform_template_renderer'

TDK = TerraformDevKit

RSpec.describe TDK::TerraformTemplateRenderer do
  before(:example) do
    @initial_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    # TODO: get rid of ROOT_PATH
    ROOT_PATH = @tmpdir
  end

  after(:example) do
    Dir.chdir(@initial_dir)
    FileUtils.rm_rf(@tmpdir, secure: true)
    ROOT_PATH = nil
  end

  describe '#render_files' do
    context 'only files in current directory' do
      let(:config_file) do
        %(
          aws:
            region: dummyregion
          project-name: some project
        )
      end

      let(:tf_template) do
        %(
          locals {
            env = "{{Environment}}"
            project_name = "{{ProjectName}}"
            project_acronym = "{{ProjectAcronym}}"
          }
        )
      end

      let(:tf_output) do
        %(
          locals {
            env = "dev"
            project_name = "some-project"
            project_acronym = "SP"
          }
        )
      end

      before(:example) do
        File.open('test.tf.mustache', 'w') { |f| f.write(tf_template) }
        File.open('config.yml', 'w') { |f| f.write(config_file) }
      end

      it 'render files in current directory' do
        # TODO: find a way to make Configuration not a singleton
        TDK::Configuration.init('config.yml')

        env = TDK::Environment.new('dev')
        project = double(name: 'some-project', acronym: 'SP')

        FileUtils.makedirs(env.working_dir)

        TDK::TerraformTemplateRenderer
          .new(env, project)
          .render_files

        expect(File.read('envs/dev/test.tf')).to eq(tf_output)
      end
    end

    context 'extra template dirs' do
      let(:config_file) do
        %(
          aws:
            region: dummyregion
          project-name: some project
          template-dirs:
            foo: foo
        )
      end

      let(:tf_template) do
        %(
          locals {
            env = "{{Environment}}"
            project_name = "{{ProjectName}}"
            project_acronym = "{{ProjectAcronym}}"
          }
        )
      end

      let(:tf_output) do
        %(
          locals {
            env = "dev"
            project_name = "some-project"
            project_acronym = "SP"
          }
        )
      end

      let(:json_template) do
        %(
          {
            "env": "{{Environment}}"
          }
        )
      end

      let(:json_output) do
        %(
          {
            "env": "dev"
          }
        )
      end

      before(:example) do
        File.open('test.tf.mustache', 'w') { |f| f.write(tf_template) }
        FileUtils.makedirs('foo')
        File.open('foo/bar.json.mustache', 'w') { |f| f.write(json_template) }
        File.open('config.yml', 'w') { |f| f.write(config_file) }
      end

      it 'render files in extra template directories' do
        # TODO: find a way to make Configuration not a singleton
        TDK::Configuration.init('config.yml')

        env = TDK::Environment.new('dev')
        project = double(name: 'some-project', acronym: 'SP')

        FileUtils.makedirs(env.working_dir)

        TDK::TerraformTemplateRenderer
          .new(env, project)
          .render_files

        expect(File.read('envs/dev/test.tf')).to eq(tf_output)
        expect(File.read('envs/dev/foo/bar.json')).to eq(json_output)
      end
    end

    context 'extra variables are passed' do
      let(:config_file) do
        %(
          aws:
            region: dummyregion
          project-name: some project
        )
      end

      let(:tf_template) do
        %(
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
          locals {
            env = "dev"
            dummy = "foobar"
            project_name = "some-project"
            project_acronym = "SP"
          }
        )
      end

      before(:example) do
        File.open('test.tf.mustache', 'w') { |f| f.write(tf_template) }
        File.open('config.yml', 'w') { |f| f.write(config_file) }
      end

      it 'render files in current directory' do
        # TODO: find a way to make Configuration not a singleton
        TDK::Configuration.init('config.yml')

        env = TDK::Environment.new('dev')
        project = double(name: 'some-project', acronym: 'SP')

        FileUtils.makedirs(env.working_dir)

        TDK::TerraformTemplateRenderer
          .new(env, project, proc { { Dummy: 'foobar' } })
          .render_files

        expect(File.read('envs/dev/test.tf')).to eq(tf_output)
      end
    end
  end
end
