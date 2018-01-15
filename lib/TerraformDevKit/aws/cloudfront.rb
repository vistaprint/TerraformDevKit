require 'aws-sdk-cloudfront'
require 'TerraformDevKit'


module TerraformDevKit::Aws
  class CloudFront 
    def initialize(credentials, region)
      @cloudfront = Aws::CloudFront::Client.new(
        region: region, 
        credentials:credentials
      )
    end

    def distribution_is_deployed?(distribution_id)
      @cloudfront.get_distribution({
        id: distribution_id, 
      }).distribution.status == 'Deployed'
    end
  end
end
