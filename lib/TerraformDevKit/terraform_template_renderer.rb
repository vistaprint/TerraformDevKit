require 'fileutils'
require 'TerraformDevKit/terraform_template_config_file'

module TerraformDevKit
  class TerraformTemplateRenderer
    def initialize(env, project, extra_vars_proc)
      @env = env
      @project = project
      @extra_vars_proc = extra_vars_proc
    end

    def render_files
      template_dirs = Configuration.get('template-dirs')
      render_files_into_path(Dir['*.mustache'])
      template_dirs.to_h.each do |dest, src|
        render_files_into_path(Dir[File.join(src, '*.mustache')], dest)
      end
    end

    private

    def render_files_into_path(file_list, dest_path = '.')
      aws_config = Configuration.get('aws')
      file_list.each do |fname|
        template_file = TerraformTemplateConfigFile.new(
          File.read(fname),
          @project,
          @env,
          aws_config,
          extra_vars: @extra_vars_proc.call(@env)
        )
        config_fname = File.basename(fname, File.extname(fname))
        Dir.chdir(@env.working_dir) do
          FileUtils.makedirs(dest_path)
          config_fname = File.join(dest_path, config_fname)
          File.open(config_fname, 'w') { |f| f.write(template_file.render) }
        end
      end
    end
  end
end
