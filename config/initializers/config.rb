APP_CONFIG = HashWithIndifferentAccess.new(YAML.load_file(File.expand_path('../../config.yml', __FILE__)).fetch(Rails.env, {}))
