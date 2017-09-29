require 'TerraformDevKit/terraform_template_config_file'

require 'fileutils'

module TerraformDevKit
  class TerraformConfigManager
    def self.setup(env, extra_vars)
      fix_configuration(env)
      create_environment_directory(env)
      render_template_config_files(env, extra_vars)
    end

    def self.update_modules?
      skip_update = ENV.fetch('TF_DEV_KIT_SKIP_MODULE_UPDATE', 'false')
                       .strip
                       .downcase
      skip_update != 'true'
    end

    private_class_method
    def self.fix_configuration(env)
      if env.running_on_jenkins?
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
    def self.render_template_config_files(env, extra_vars)
      aws_config = Configuration.get('aws')
      file_list = Dir['*.tf.mustache'] + Dir['*.tfvars.mustache']
      file_list.each do |fname|
        template_file = TerraformTemplateConfigFile.new(
          File.read(fname),
          env,
          aws_config,
          extra_vars: extra_vars
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
      raise 'Invalid profile name' unless /^\w+$/ =~ profile
      profile
    end
  end
end
