require 'fileutils'
require 'TerraformDevKit/command'
require 'TerraformDevKit/os'

module ExtendedFileUtils
  def rm_rf(list, options = {})
    if TerraformDevKit::OS.host_os == 'windows'
      windows_path = TerraformDevKit::OS.convert_to_local_path(list)
      TerraformDevKit::Command.run("rmdir /s/q \"#{windows_path}\"")
    else
      FileUtils.rm_rf(list, options)
    end
  end
  module_function :rm_rf
end
