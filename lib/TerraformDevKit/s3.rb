require 'aws-sdk-s3'

Aws.use_bundled_cert!

module TerraformDevKit
  # Wrapper class around aws s3
  class S3
    def initialize(credentials, region)
      @s3_client = Aws::S3::Client.new(
        credentials: credentials,
        region: region
      )
    end

    def create_bucket(bucket_name)
      @s3_client.create_bucket(
        bucket: bucket_name
      )
    end

    def delete_bucket(bucket_name)
      empty_bucket(bucket_name)

      @s3_client.delete_bucket(
        bucket: bucket_name
      )
    end

    def empty_bucket(bucket_name)
      keys_to_delete = @s3_client
                       .list_objects_v2(bucket: bucket_name)
                       .contents
                       .map { |x| { key: x.key } }

      @s3_client.delete_objects(
        bucket: bucket_name,
        delete: {
          objects: keys_to_delete
        }
      )
    end
  end
end
