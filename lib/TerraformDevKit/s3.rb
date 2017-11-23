require 'aws-sdk'

Aws.use_bundled_cert!

module TerraformDevKit
  # Wrapper class around aws s3
  class S3
    def initialize(credentials, region)
      @s3_client = Aws::S3::Resource.new(
        credentials: credentials,
        region: region
      )
    end
  
    def create_bucket(bucket_name)
      @s3_client.create_bucket({
        bucket: bucket_name 
      })
    end
  end
end
