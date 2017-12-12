require 'TerraformDevKit/s3'

RSpec.describe TerraformDevKit::S3 do
  let(:region) { 'some-region' }
  let(:credentials) { 'some-credentials' }
  let(:bucket_name) { 'some-bucket' }
  let(:response) {
    double(
      contents: [
        double(key: 'key-1'),
        double(key: 'key-2')
      ]
    )
  }

  it 'should destroy all files in the bucket before destroying the bucket' do
    aws_s3_double = instance_double('Aws::S3::Client')

    expect(Aws::S3::Client)
      .to receive(:new)
      .with(
        credentials: credentials,
        region: region
      ).and_return(aws_s3_double)

    expect(aws_s3_double)
      .to receive(:list_objects_v2)
      .with(
        bucket: bucket_name
      ).and_return(response)

    expect(aws_s3_double)
      .to receive(:delete_objects)
      .with(
        bucket: bucket_name,
        delete: {
          objects: [{ key: 'key-1' }, { key: 'key-2' }]
        }
      )

    expect(aws_s3_double)
      .to receive(:delete_bucket)
      .with(
        bucket: bucket_name
      )

    s3 = TerraformDevKit::S3.new(credentials, region)
    s3.delete_bucket(bucket_name)
  end
end
