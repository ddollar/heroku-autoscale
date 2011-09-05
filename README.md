# Heroku::Autoscale

## WARNING

  This gem is a proof of concept and should not be used in production applications.
  There is currently no mechanism to prevent multiple dynos on the same app all running this code
  from fighting each other for control.

## Installation

    # Gemfile
    gem 'heroku-autoscale'

## Usage (Rails 2.x)

    # config/environment.rb
    config.middleware.use Heroku::Autoscale,
      :username  => ENV["HEROKU_USERNAME"],
      :password  => ENV["HEROKU_PASSWORD"],
      :app_name  => ENV["HEROKU_APP_NAME"],
      :min_dynos => 2,
      :max_dynos => 5,
      :queue_wait_low  => 100,  # milliseconds
      :queue_wait_high => 5000, # milliseconds
      :min_frequency   => 10    # seconds
    
## Usage (Rails 3 / Rack)

    # config.ru
    use Heroku::Autoscale,
      :username  => ENV["HEROKU_USERNAME"],
      :password  => ENV["HEROKU_PASSWORD"],
      :app_name  => ENV["HEROKU_APP_NAME"],
      :min_dynos => 2,
      :max_dynos => 5,
      :queue_wait_low  => 100,  # milliseconds
      :queue_wait_high => 5000, # milliseconds
      :min_frequency   => 10    # seconds