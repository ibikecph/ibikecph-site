RailsOSRM::Application.configure do

  # note:
  # heroku config vars normally stored in ENV is not available during asset precompiling
  # see https://devcenter.heroku.com/articles/rails3x-asset-pipeline-cedar

  MAIN_DOMAIN = ENV['DOMAIN']
  WEB_DOMAIN = ENV['WEB_DOMAIN']

  # google analytics
  GA.tracker = ENV['GOOGLE_ANALYTICS_KEY']

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  config.assets.initialize_on_precompile = false

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # note: serving asset from Amazon CloudFront from a custom domain via https
  # requires using either paying or usign SNI which doens't work on all browswer.
  # for the time being we just use the cloudfront domain name instead.
  config.action_controller.asset_host = ENV['ASSET_HOST']

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( map.css )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.eager_load = false

  # ActionMailer Config
  config.action_mailer.default_url_options = { :host => WEB_DOMAIN }

  # Setup Workless
  config.after_initialize do
    if ENV['WORKLESS'] == 'on'
      Delayed::Job.scaler = :heroku_cedar
    else
      Delayed::Job.scaler = :null
    end
  end
  
  # only send email to whitelisted addressed, useful during staging
  if ENV['INTERCEPT_EMAIL']
    Mail.register_interceptor RecipientInterceptor.new(ENV['INTERCEPT_EMAIL'])
  end
  
  config.middleware.use ExceptionNotification::Rack,
    :email => {
      :email_prefix => "[Exception] ",
      :sender_address => %{"notifier" <auto@#{MAIN_DOMAIN}>},
      :exception_recipients => ENV['EXCEPTION_RECIPIENTS']
    }

  # this replaces the rails_12factor gem, see
  # https://devcenter.heroku.com/articles/getting-started-with-rails5#heroku-gems
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

end
