Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.active_storage.service = :local
  config.log_level = :info
end
