require 'TerraformDevKit/aws/cloudfront'

RSpec.describe TerraformDevKit::Aws::CloudFront do
  
  let(:region) { 'some-region' }
  let(:credentials) { 'some-credentials' }
  let(:distribution_id) { 'some-distribution' }
  let(:in_progress_response) {
    double(
      distribution: 
        double(status: 'InProgress')
      
    )
  }
  let(:deployed_response) {
    double(
      distribution: 
         double(status: 'Deployed') 
    )
  }

  describe '#is_deployed?' do
    context 'cloudfront distribution is deployed' do
      it 'should return true' do
        aws_cloudfront_double = instance_double('Aws::CloudFront::Client')
      
        expect(::Aws::CloudFront::Client)
          .to receive(:new)
          .with(
            credentials: credentials,
            region: region
          ).and_return(aws_cloudfront_double)

        expect(aws_cloudfront_double)
          .to receive(:get_distribution)
          .with(
            id: distribution_id
          ).and_return(deployed_response)

          cloudfront = TerraformDevKit::Aws::CloudFront.new(credentials, region)
          expect(cloudfront.distribution_is_deployed?(distribution_id)).to eq(true)
      end
    end

    context 'cloudfront distribution is InProgress' do
      it 'should return false' do
        aws_cloudfront_double = instance_double('Aws::CloudFront::Client')
      
        expect(Aws::CloudFront::Client)
          .to receive(:new)
          .with(
            credentials: credentials,
            region: region
          ).and_return(aws_cloudfront_double)

        expect(aws_cloudfront_double)
          .to receive(:get_distribution)
          .with(
            id: distribution_id
          ).and_return(deployed_response)

          cloudfront = TerraformDevKit::Aws::CloudFront.new(credentials, region)
          expect(cloudfront.distribution_is_deployed?(distribution_id)).to eq(true)
      end
    end
  end
end