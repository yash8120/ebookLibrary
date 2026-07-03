require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module EbookLibrary
  class Application < Rails::Application
    config.load_defaults 7.1

    # API-only mode: no views, no cookies/sessions, no CSRF.
    config.api_only = true

    config.autoload_lib(ignore: %w[assets tasks])
  end
end
