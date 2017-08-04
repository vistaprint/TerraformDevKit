require 'webmock/rspec'

require 'TerraformDevKit/request'

Request = TerraformDevKit::Request

RSpec.describe Request do
  before(:example) do
    WebMock.enable!
  end

  after(:example) do
    WebMock.disable!
  end

  context 'request is successful' do
    let(:url) { 'http://www.example.com' }
    let(:status) { 200 }
    let(:body) { 'OK' }
    let(:content_type) { 'text/plain' }

    before(:example) do
      stub_request(:get, url)
        .to_return(
          status: status,
          body: body,
          headers: { 'Content-Type' => content_type }
        )
    end

    it 'returns a response' do
      response = Request.new(url).execute
      expect(response.read).to eq(body)
      expect(response.base_uri.to_s).to eq(url)
      expect(response.status[0]).to eq(status.to_s)
      expect(response.content_type).to eq(content_type)
    end
  end

  context 'request is an error' do
    let(:url) { 'http://www.example.com' }
    let(:status) { 400 }
    let(:body) { 'ERROR' }
    let(:content_type) { 'text/plain' }

    before(:example) do
      stub_request(:get, url)
        .to_return(
          status: status,
          body: body,
          headers: { 'Content-Type' => content_type }
        )
    end

    it 'returns a response' do
      response = Request.new(url).execute
      expect(response.read).to eq(body)
      expect(response.status[0]).to eq(status.to_s)
      expect(response.content_type).to eq(content_type)
    end

    it 'raises if status code in raise list' do
      expect {
        Request.new(url).execute(raise_on_codes: ['400'])
      }.to raise_error(OpenURI::HTTPError)
    end
  end

  context 'request is a redirect' do
    let(:url) { 'http://www.example.com'}
    let(:status) { 301 }
    let(:body) { 'REDIRECTED' }
    let(:content_type) { 'text/plain' }
    let(:redirect_url) { 'http://www.example.com/redirect' }

    before(:example) do
      stub_request(:get, url)
        .to_return(
          status: status,
          body: body,
          headers: { 'Content-Type' => content_type, 'Location' => redirect_url })
    end

    it 'returns a response and the redirect URL' do
      response = Request.new(url).execute
      expect(response.read).to eq(body)
      expect(response.status[0]).to eq(status.to_s)
      expect(response.content_type).to eq(content_type)
      expect(response.meta['location']).to eq(redirect_url)
    end

    it 'raises if status code in raise list' do
      expect {
        Request.new(url).execute(raise_on_codes: ['301'])
      }.to raise_error(OpenURI::HTTPError)
    end
  end

  context 'when query strings are used' do
    let(:base_url) { 'http://www.example.com'}
    let(:url) { "#{base_url}?a=1&b=2" }
    let(:query_strings) { [%w[a 1], %w[b 2]] }
    let(:status) { 200 }
    let(:body) { 'OK' }
    let(:content_type) { 'text/plain' }

    before(:example) do
      stub_request(:get, url)
        .to_return(
          status: status,
          body: body,
          headers: { 'Content-Type' => content_type })
    end

    it 'query strings are added to the URL' do
      response = Request.new(base_url, query_strings: query_strings).execute
      expect(response.read).to eq(body)
      expect(response.base_uri.to_s).to eq(url)
      expect(response.status[0]).to eq(status.to_s)
      expect(response.content_type).to eq(content_type)
    end
  end

  context 'when headers are passed' do
    let(:url) { 'http://www.example.com'}
    let(:headers) { { 'Content-Type' => 'text/plain' } }
    let(:status) { 200 }
    let(:body) { 'OK' }
    let(:content_type) { 'text/plain' }

    before(:example) do
      stub_request(:get, url)
        .with(headers: headers)
        .to_return(
          status: status,
          body: body,
          headers: { 'Content-Type' => content_type })
    end

    it 'query strings are added to the URL' do
      response = Request.new(url, headers: headers).execute
      expect(response.read).to eq(body)
      expect(response.base_uri.to_s).to eq(url)
      expect(response.status[0]).to eq(status.to_s)
      expect(response.content_type).to eq(content_type)
    end
  end
end
