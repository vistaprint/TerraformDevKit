require 'TerraformDevKit/terraform_lock_table'

RSpec.describe TerraformDevKit::TerraformLockTable do

  let(:dynamodb_double) { double() }
  let(:s3_double) { double() }

  let(:project_double) { double(name: 'dummy-project', acronym: 'DP') }
  let(:environment_double) { double(config: 'dev') }

  let(:terraform_lock_table) { 
    TerraformDevKit::TerraformLockTable.new(dynamodb_double, s3_double) 
  }


  context 'lock table does not exist' do
    it 'creates the lock table and waits until active' do
      attributes = [
        {
          attribute_name: "LockID", 
          attribute_type: "S", 
        }
      ]	      
      keys = [
        {
          attribute_name: "LockID", 
          key_type: "HASH", 
        }
      ]
      
      allow(dynamodb_double)
        .to receive(:get_table_status)
        .and_return("INACTIVE", "INACTIVE","ACTIVE")
      
      expect(dynamodb_double)
        .to receive(:create_table)
        .with('DP-dev-lock-table', attributes, keys, 1, 1)
        .once
      
      expect(dynamodb_double)
        .to receive(:get_table_status)
        .exactly(3)
        .times      

      expect(s3_double)
        .to receive(:create_bucket)
        .with('dummy-project')
     
      terraform_lock_table
        .create_lock_table_if_not_exists(environment_double, project_double)
    end
  end

  context 'lock table exists and is active' do
    it 'does nothing' do
      expect(dynamodb_double)
        .to receive(:get_table_status)
        .and_return("ACTIVE")
        .once
      
      expect(s3_double)
        .to receive(:create_bucket)
        .never
      
      terraform_lock_table
        .create_lock_table_if_not_exists(environment_double, project_double)
    end
  end

end