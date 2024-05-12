class OpensearchDashboardController < ApplicationController
  include ReverseProxy::Controller

  def index
    signer = Aws::Sigv4::Signer.new(
      service: 'es',
      region: 'ap-sotheast-2',
      credentials: Aws::ECSCredentials.new
    )

    signed_url = signer.presign_url(
      http_method: request.method,
      url: "https://#{opensearch_domain}/#{params[:path]}",
      body: request.body,
      headers: {
        'Host' => opensearch_domain
      }
    )
    reverse_proxy signed_url do |config|
      # We got a 404!
      # config.on_missing do |_code, _response|
      #   redirect_to root_url and return
      # end
    end
  end
end
