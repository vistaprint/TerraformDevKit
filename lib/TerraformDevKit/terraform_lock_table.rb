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

      table_name = "#{project.acronym}-#{environment.name}-lock-table"
      return if lock_table_exists_and_is_active(table_name)

      bucket_name = "#{project.name}"
      @dynamodb.create_table(table_name, @attributes, @keys, 1, 1)

      begin
        @s3.create_bucket(bucket_name)
      rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
      end


      while !lock_table_exists_and_is_active(table_name) do
        sleep(0.2)
      end
    end
    
    private_class_method
    def lock_table_exists_and_is_active(table_name)
      begin  
        return @dynamodb.get_table_status(table_name) == "ACTIVE"
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException
        return false
      end
    end
  end
end