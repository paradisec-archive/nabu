Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/oauth/token', headers: :any, methods: [:post]
    resource '/api/v1/oni/search', headers: :any, methods: [:post]
    resource '/api/v1/oni/*', headers: :any, methods: [:get]
  end
end
