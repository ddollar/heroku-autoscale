require "eventmachine"
require "heroku"
require "rack"

module Heroku
  class Autoscale

    VERSION = "0.2.1"

    attr_reader :app, :options, :last_scaled

    def initialize(app, options={})
      @app = app
      @options = default_options.merge(options)
      @last_scaled = Time.now - 60
      check_options!
    end

    def call(env)
      if options[:defer]
        EventMachine.defer { autoscale(env) }
      else
        autoscale(env)
      end

      app.call(env)
    end

private ######################################################################

    def autoscale(env)
      original_dynos = dynos = current_dynos
      wait = queue_wait(env)

      dynos -= 1 if wait <= options[:queue_wait_low]
      dynos += 1 if wait >= options[:queue_wait_high]

      dynos = options[:min_dynos] if dynos < options[:min_dynos]
      dynos = options[:max_dynos] if dynos > options[:max_dynos]
      dynos = 1 if dynos < 1

      set_dynos(dynos) if dynos != original_dynos
    end

    def check_options!
      errors = []
      errors << "Must supply :username to Heroku::Autoscale" unless options[:username]
      errors << "Must supply :password to Heroku::Autoscale" unless options[:password]
      errors << "Must supply :app_name to Heroku::Autoscale" unless options[:app_name]
      raise errors.join(" / ") unless errors.empty?
    end

    def current_dynos
      heroku.info(options[:app_name])[:dynos].to_i
    end

    def default_options
      {
        :defer           => true,
        :min_dynos       => 1,
        :max_dynos       => 1,
        :queue_wait_high => 5000, # milliseconds
        :queue_wait_low  => 0,    # milliseconds
        :min_frequency   => 10    # seconds
      }
    end

    def heroku
      @heroku ||= Heroku::Client.new(options[:username], options[:password])
    end

    def queue_wait(env)
      env["HTTP_X_HEROKU_QUEUE_WAIT_TIME"].to_i
    end

    def set_dynos(count)
      return if (Time.now - last_scaled) < options[:min_frequency]
      heroku.set_dynos(options[:app_name], count)
      @last_scaled = Time.now
    end

  end
end
