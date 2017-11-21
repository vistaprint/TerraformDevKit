
module TerraformDevKit
  class TerraformLockTable

    def initialize(dynamodb)
      @dynamodb = dynamodb
      @attributes = [
        {
          attribute_name: "LockID", 
          attribute_type: "S", 
        }
      ]	
      @keys = [
        {
          attribute_name: "LockID", 
          key_type: "HASH", 
        }
      ]
    end

    def create_lock_table(environment, project)
      table_name = "#{project.acronym}-#{environment.config}-lock-table"
      @dynamodb.create_table(table_name, @attributes, @keys, 1, 1)

      while !@dynamodb.is_table_active(table_name) do
        sleep(0.2)
      end
    end

  end
end