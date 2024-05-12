class OpensearchDashboardController < ApplicationController
  protect_from_forgery except: :index

  include ReverseProxy::Controller

  def index
    opensearch_domain = ENV.fetch('OPENSEARCH_URL', nil).sub('https://', '')

    # NOTE: Signing wouldn;t work unless we escapes things like *
    uri = URI.parse(request.fullpath)
    if uri.query
      encoded_query = URI.decode_www_form(uri.query).map do |key, value|
        "#{URI.encode_www_form_component(key)}=#{CGI.escape(value)}"
      end.join('&')
      path = "#{uri.path}?#{encoded_query}"
    else
      path = uri.path
    end

    signer = Aws::Sigv4::Signer.new(
      service: 'es',
      region: 'ap-southeast-2',
      credentials_provider: Aws::ECSCredentials.new
    )

    # NOTE: Need to use headers as opensearch tries to do things with the AMZ- query parameters
    signed_request = signer.sign_request(
      http_method: request.method,
      url: "https://#{opensearch_domain}#{path}",
      body: request.body,
      headers: {
        'Host' => opensearch_domain
      }
    )

    reverse_proxy "https://#{opensearch_domain}", path:, headers: signed_request.headers
  end
end
