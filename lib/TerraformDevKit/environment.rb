require 'socket'

module TerraformDevKit
  class Environment
    attr_reader :name

    def initialize(name)
      raise 'Environment must not be null' if name.nil?
      raise "Invalid environment name: #{name}" unless /^[0-9a-zA-Z]+$/ =~ name
      @name = name.downcase
    end

    def config
      case @name
      when 'prod'
        'prod'
      when 'test'
        'test'
      else
        'dev'
      end
    end

    def local_backend?
      case @name
      when 'prod', 'test'
        false
      else
        true
      end
    end

    def working_dir
      "envs/#{@name}"
    end

    def self.temp_name
      hostname = Socket.gethostname
      date = Time.now.strftime('%y%m%d%H%M')
      "#{hostname}#{date}"
    end

    def self.running_on_jenkins?
      ENV.key?('JENKINS_URL') && ENV.key?('BUILD_ID')
    end
  end
end
