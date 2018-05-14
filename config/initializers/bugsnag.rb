if ENV.fetch('RAILS_ENV') == 'production'
  Bugsnag.configure do |config|
    config.api_key = ENV.fetch('BUGSNAG_API_KEY')
    config.notify_release_stages = [ 'production' ]
  end

  Bugsnag.before_notify_callbacks << lambda { |notification|
    notification.context = 'ENTER CUSTOMER HERE'
  }
end
