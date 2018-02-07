require 'fileutils'
require 'TerraformDevKit/command'
require 'TerraformDevKit/os'

module TerraformDevKit::ExtendedFileUtils
  def self.copy(files, dest_base_path)
    files.to_h.each do |dest, src|
      dest = File.join(dest_base_path, dest)
      FileUtils.copy_entry(src, dest)
    end
  end

  def self.rm_rf(list, options = {})
    if TerraformDevKit::OS.host_os == 'windows'
      windows_path = TerraformDevKit::OS.convert_to_local_path(list)
      TerraformDevKit::Command.run("rmdir /s/q \"#{windows_path}\"")
    else
      FileUtils.rm_rf(list, options)
    end
  end
end
