module TerraformDevKit
  class OS
    def self.host_os
      case RUBY_PLATFORM
      when /linux/
        'linux'
      when /darwin/
        'darwin'
      when /mingw/
        'windows'
      else
        raise 'Cannot determine OS'
      end
    end

    def self.env_path_separator
      case host_os
      when 'linux', 'darwin'
        ':'
      when 'windows'
        ';'
      end
    end

    def self.join_env_path(path1, path2)
      "#{path1}#{env_path_separator}#{path2}"
    end

    # If running on Windows, this function converts a path separated with
    # forward slashes (the default for Ruby) into a path that uses backslashes.
    def self.convert_to_local_path(path)
      path.gsub(
        File::SEPARATOR,
        File::ALT_SEPARATOR || File::SEPARATOR)
    end
  end
end
