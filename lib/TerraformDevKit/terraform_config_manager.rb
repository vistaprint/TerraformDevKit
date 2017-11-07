require 'TerraformDevKit/terraform_template_config_file'

require 'fileutils'

module TerraformDevKit
  class TerraformConfigManager
    @extra_vars_proc = proc { {} }

    def self.register_extra_vars_proc(p)
      @extra_vars_proc = p
    end

    def self.setup(env)
      fix_configuration(env)
      create_environment_directory(env)
      render_template_config_files(env)
    end

    def self.update_modules?
      skip_update = ENV.fetch('TF_DEVKIT_SKIP_MODULE_UPDATE', 'false')
                       .strip
                       .downcase
      skip_update != 'true'
    end

    private_class_method
    def self.fix_configuration(env)
      raise 'No AWS section in the config file' if Configuration.get('aws').nil?
      if Environment.running_on_jenkins?
        Configuration.get('aws').delete('profile')
      elsif Configuration.get('aws').key?('profile')
        unless env.local_backend?
          raise "AWS credentials for environment #{env.name} must not be stored!"
        end
      else
        profile = request_profile(env)
        Configuration.get('aws')['profile'] = profile
      end
    end

    private_class_method
    def self.create_environment_directory(env)
      FileUtils.makedirs(env.working_dir)
    end

    private_class_method
    def self.render_template_config_files(env)
      aws_config = Configuration.get('aws')
      file_list = Dir['*.tf.mustache'] + Dir['*.tfvars.mustache']
      file_list.each do |fname|
        template_file = TerraformTemplateConfigFile.new(
          File.read(fname),
          env,
          aws_config,
          extra_vars: @extra_vars_proc.call(env)
        )
        config_fname = File.basename(fname, File.extname(fname))
        Dir.chdir(env.working_dir) do
          File.open(config_fname, 'w') { |f| f.write(template_file.render) }
        end
      end
    end

    private_class_method
    def self.request_profile(env)
      puts "Environment #{env.name} requires manual input of AWS credentials"
      print 'Enter the profile to use: '
      profile = $stdin.gets.tr("\r\n", '')
      /^\w+$/ =~ profile || (raise 'Invalid profile name')
      profile
    end
  end
end
