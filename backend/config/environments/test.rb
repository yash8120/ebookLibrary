Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.active_storage.service = :test
  config.action_controller.allow_forgery_protection = false
  config.log_level = :warn
end
