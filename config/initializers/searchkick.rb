if ENV['ASSET_PRECOMPILE'].blank? && !Rails.env.development? && !Rails.env.test?
  Searchkick.aws_credentials = {
    region: 'ap-southeast-2',
    credentials_provider: Aws::ECSCredentials.new
  }
end
