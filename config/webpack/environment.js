const { environment } = require('@rails/webpacker')

module.exports = environment

environment.loaders.prepend('erb', {
  test: /\.erb$/,
  enforce: 'pre',
  use: [{
    loader: 'rails-erb-loader',
    options: {
      // runner: '/usr/local/bin/ruby bin/rails runner',
      env: {
        DISABLE_SPRING: 1,
        BUNDLE_PATH: '/bundler',
        BUNDLE_HOME: '/gems',
        GEM_HOME: ' /gems',
        GEM_PATH: '/gems',
        PATH: '/gems/bin:/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
      }
    }
  }]
});
