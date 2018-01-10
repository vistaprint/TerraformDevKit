require 'aws-sdk-dynamodb'

Aws.use_bundled_cert!

module TerraformDevKit
  # Wrapper class around aws dynamodb
  class DynamoDB
    def initialize(credentials, region)
      @db_client = Aws::DynamoDB::Client.new(
        credentials: credentials,
        region: region
      )
    end

    def put_item(table_name, item)
      @db_client.put_item({item: item, table_name: table_name})
    end

    def create_table(table_name, attributes, keys, read_capacity, write_capacity)
      @db_client.create_table(
        attribute_definitions: attributes,
        key_schema: keys,
        provisioned_throughput: {
          read_capacity_units: read_capacity,
          write_capacity_units: write_capacity
        },
        table_name: table_name
      )
    end

    def get_table_status(table_name)
      resp = @db_client.describe_table({
        table_name: table_name,
      })
      resp.table.table_status
    end

    def delete_table(table_name)
      @db_client.delete_table({
        table_name: table_name,
      })
    end

  end
end
