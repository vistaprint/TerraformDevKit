require 'aws-sdk'

module TerraformDevKit
  # Represents a terraform lock table.
  class TerraformLockTable
    ATTRIBUTES = [
        {
          attribute_name: 'LockID',
          attribute_type: 'S'
        }
      ]
    KEYS = [
        {
          attribute_name: 'LockID',
          key_type: 'HASH'
        }
      ]

    def initialize(dynamodb, s3)
      @dynamodb = dynamodb
      @s3 = s3
    end

    def create_lock_table_if_not_exists(environment, project)
      table_name = genertate_table_name(environment, project)
      return if lock_table_exists_and_is_active(table_name)

      @dynamodb.create_table(table_name, ATTRIBUTES, KEYS, 1, 1)

      begin
        @s3.create_bucket(genertate_state_bucket_name(environment, project))
      rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
        return
      end

      sleep(0.2) until lock_table_exists_and_is_active(table_name)

    end

    def destroy_lock_table(environment, project)
      table_name = genertate_table_name(environment, project)

      @dynamodb.delete_table(table_name)
      @s3.delete_bucket(genertate_state_bucket_name(environment, project))
    end

    private_class_method
    def lock_table_exists_and_is_active(table_name)
      begin
        return @dynamodb.get_table_status(table_name) == 'ACTIVE'
      rescue Aws::DynamoDB::Errors::ResourceNotFoundException
        return false
      end
    end

    private_class_method
    def genertate_table_name(environment, project)
      "#{project.acronym}-#{environment.name}-lock-table"
    end

    private_class_method
    def genertate_state_bucket_name(environment, project)
      "#{project.name}-#{environment.name}-state"
    end
  end
end
