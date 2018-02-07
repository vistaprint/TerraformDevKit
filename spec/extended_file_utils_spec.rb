require 'fileutils'
require 'tmpdir'

require 'TerraformDevKit/extended_file_utils'

TDK = TerraformDevKit

RSpec.describe TDK::ExtendedFileUtils do
  before(:each) do
    @initial_dir = Dir.getwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
  end

  after(:each) do
    Dir.chdir(@initial_dir)
    FileUtils.rm_rf(@tmpdir, secure: true)
  end

  describe '#copy' do
    it 'copies files to destination folder' do
      create_files(%w[
        src/file1
        src/dir1/file2
        src/dir1/dir2/file3
        src/dir3/file4
      ])

      FileUtils.makedirs('dest')

      TDK::ExtendedFileUtils.copy({ 'src' => 'src' }, 'dest')

      expect(File.exist?('dest/src/file1')).to be true
      expect(File.exist?('dest/src/dir1/file2')).to be true
      expect(File.exist?('dest/src/dir1/dir2/file3')).to be true
      expect(File.exist?('dest/src/dir3/file4')).to be true
    end
  end

  describe '#rm_rf' do
    it 'recursively removes files' do
      create_files(%w[
        foo/bar/hoge
      ])

      TDK::ExtendedFileUtils.rm_rf('foo', secure: true)

      expect(File.exist?('foo')).to be false
    end
  end

  def create_files(files)
    files.each do |file|
      dir = File.dirname(file)
      FileUtils.makedirs(dir)
      File.open(file, 'w').close
    end
  end
end
