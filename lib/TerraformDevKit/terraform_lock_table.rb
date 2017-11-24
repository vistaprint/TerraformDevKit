require 'aws-sdk'

module TerraformDevKit
  class TerraformLockTable

    def initialize(dynamodb, s3)
      @dynamodb = dynamodb
      @s3 = s3
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

    def create_lock_table_if_not_exists(environment, project)
      table_name = genertate_table_name(environment, project)
      return if lock_table_exists_and_is_active(table_name)

      @dynamodb.create_table(table_name, @attributes, @keys, 1, 1)

      begin
        @s3.create_bucket(project.name)
      rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
      end

      while !lock_table_exists_and_is_active(table_name) do
        sleep(0.2)
      end
    end

    def destroy_lock_table(environment, project)
      table_name = genertate_table_name(environment, project)

      @dynamodb.delete_table(table_name)
      @s3.delete_bucket(project.name)
    end
    
    private_class_method
    def lock_table_exists_and_is_active(table_name)
      begin  
        return @dynamodb.get_table_status(table_name) == "ACTIVE"
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException
        return false
      end
    end

    private_class_method
    def genertate_table_name(environment, project)
      "#{project.acronym}-#{environment.name}-lock-table"
    end
  end
end