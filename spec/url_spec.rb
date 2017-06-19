require 'TerraformDevKit/url'

RSpec.describe '#valid_url?' do
  it 'returns true if url is valid' do
    url = 'http://example.com'
    expect(TerraformDevKit.valid_url?(url)).to be true

    url = 'https://example.com'
    expect(TerraformDevKit.valid_url?(url)).to be true
  end

  it 'returns false if no schema' do
    url = 'example.com'
    expect(TerraformDevKit.valid_url?(url)).to be false
  end

  it 'returns false if schema is not HTTP(S)' do
    url = 'other://example.com'
    expect(TerraformDevKit.valid_url?(url)).to be false
  end

  it 'returns false if host is empty' do
    url = 'example.com'
    expect(TerraformDevKit.valid_url?(url)).to be false
  end
end
