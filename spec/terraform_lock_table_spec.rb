require 'TerraformDevKit/terraform_lock_table'

RSpec.describe TerraformDevKit::TerraformLockTable do

  context 'lock table does not exist' do
    it 'creates the lock table and waits until active' do
      dynamodb_double = double()

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
      allow(dynamodb_double).to receive(:is_table_active).and_return(false, false, true)
      expect(dynamodb_double).to receive(:create_table).with('DP-dev-lock-table', attributes, keys, 1, 1).once
      expect(dynamodb_double).to receive(:is_table_active).exactly(3).times
      
      project_double = double()
      allow(project_double).to receive(:name).and_return('dummy-project')
      allow(project_double).to receive(:acronym).and_return('DP')

      environment_double = double()
      allow(environment_double).to receive(:config).and_return('dev')

      terraform_lock_table = TerraformDevKit::TerraformLockTable.new(dynamodb_double)

      terraform_lock_table.create_lock_table(environment_double, project_double)
    end
  end

end