# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"

pin_all_from "app/javascript/custom", under: "custom"
pin_all_from "app/javascript/vendor", under: "vendor"
pin "jquery", to: "https://cdn.jsdelivr.net/npm/jquery@1.11.3/dist/jquery.js"
pin "jquery-ui", to: "https://cdn.jsdelivr.net/npm/jquery-ui@1.13.2/dist/jquery-ui.min.js"
