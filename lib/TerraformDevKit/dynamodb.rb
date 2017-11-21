require 'aws-sdk'

Aws.use_bundled_cert!

module TerraformDevKit
  class DynamoDB
    def initialize(credentials, region)
      @db_client = Aws::DynamoDB::Resource.new(
        credentials: credentials,
        region: region
      )
    end

    def get_item(table_name, key)
      table = @db_client.table(table_name)
      table.get_item(key: key)
    end

    def put_item(table_name, item)
      table = @db_client.table(table_name)
      table.put_item(item: item)
    end

    def create_table(table_name, attributes, keys, read_capacity, write_capacity)
      @db_client.create_table({
        attribute_definitions: attributes, 
        key_schema: keys, 
        provisioned_throughput: {
          read_capacity_units: read_capacity, 
          write_capacity_units: write_capacity, 
        }, 
        table_name: table_name, 
      })
    end
  end
end
