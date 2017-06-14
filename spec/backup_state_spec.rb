require 'TerraformDevKit/backup_state'

RSpec.describe TerraformDevKit::BackupState do
  context 'no backup path is defined' do
    it 'does not do anything' do
      class_double(TerraformDevKit::ZipFileGenerator).as_stubbed_const
      class_double(FileUtils).as_stubbed_const

      TerraformDevKit::BackupState.backup('prefix')
    end
  end

  context 'a backup path is defined' do
    BACKUP_PATH = 'backup_path'.freeze

    before(:example) do
      @saved_state_backup_path = ENV['TM_STATE_BACKUP_PATH']
      ENV['TM_STATE_BACKUP_PATH'] = BACKUP_PATH
    end

    after(:example) do
      if @saved_state_backup_path.nil?
        ENV.delete('TM_STATE_BACKUP_PATH')
      else
        ENV['TM_STATE_BACKUP_PATH'] = @saved_state_backup_path
      end
    end

    it 'backs up the state' do
      zipfile_generator =
        class_double(TerraformDevKit::ZipFileGenerator).as_stubbed_const

      prefix = 'prefix'.freeze
      expected_filename = "#{prefix}failure_state.zip".freeze

      expect(zipfile_generator).to receive(:new)
        .with('.', expected_filename)
        .and_return(instance_double(TerraformDevKit::ZipFileGenerator, write: nil))

      fileutils = class_double(FileUtils).as_stubbed_const

      expect(fileutils).to receive(:cp)
        .with(expected_filename, BACKUP_PATH)

      TerraformDevKit::BackupState.backup(prefix)
    end
  end
end
