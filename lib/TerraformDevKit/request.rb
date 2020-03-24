require 'open-uri'
require 'openssl'

module TerraformDevKit
  class Request
    def initialize(url, query_strings: [], headers: {})
      @url = url
      @query_strings = query_strings
      @headers = headers
    end

    def execute(raise_on_codes: [])
      url = URI.parse(@url)
      url.query = URI.encode_www_form(@query_strings) unless @query_strings.empty?
      puts "Fetching #{url}"
      options = {
        redirect: false,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
      options.merge!(@headers)
      URI.open(url, options)
    rescue OpenURI::HTTPError => error
      response = error.io
      raise if raise_on_codes.include?(response.status[0])
      response
    end
  end
end
