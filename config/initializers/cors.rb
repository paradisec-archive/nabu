Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # Our API is public, so we allow requests from any origin
  allow do
    origins '*'

    resource '/api/v1/oni/search', headers: :any, methods: [:post]
    resource '/api/v1/oni/*', headers: :any, methods: [:get]

    resource '/api/v1/oni/*', headers: :any, methods: [:get]

    resource '/oauth/*', headers: :any, methods: [:get, :post, :options]
    resource '/.well-known/*', headers: :any, methods: [:get, :options]
  end
end
