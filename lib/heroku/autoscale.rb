require "eventmachine"
require "heroku"
require "rack"

module Heroku
  class Autoscale

    VERSION = "0.2.2"

    attr_reader :app, :options

    def initialize(app, options={})
      @app = app
      @options = default_options.merge(options)
      self.last_scaled ||= Time.now - 60
      @supported_cache = !!(Rails.cache.class.name =~ /MemCacheStore$/)
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
      # dont do anything if we scaled too frequently ago
      return if (Time.now - last_scaled) < options[:min_frequency]
      # dont do anything if we can't obtain a lock
      return if supported_cache? && !obtain_lock

      original_dynos = dynos = current_dynos
      wait = queue_wait(env)

      dynos -= 1 if wait <= options[:queue_wait_low]
      dynos += 1 if wait >= options[:queue_wait_high]

      dynos = options[:min_dynos] if dynos < options[:min_dynos]
      dynos = options[:max_dynos] if dynos > options[:max_dynos]
      dynos = 1 if dynos < 1

      set_dynos(dynos) if dynos != original_dynos

    ensure
      supported_cache? && release_lock
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
      heroku.set_dynos(options[:app_name], count)
      self.last_scaled = Time.now
    end

    # Locking and last_scaled via cache
    def supported_cache?
      @supported_cache
    end

    def obtain_lock
      return false if Rails.cache.read "heroku_autoscale:lock"
      # Expire lock in 30 seconds, in case something
      # happens to the server and it can't release the lock
      Rails.cache.write "heroku_autoscale:lock", true, :expires_in => 30
    end

    def release_lock
      Rails.cache.delete "heroku_autoscale:lock"
    end

    # Use either cache or instance variable to store last_scaled
    def last_scaled
      if supported_cache?
        Rails.cache.read "heroku_autoscale:last_scaled"
      else
        @last_scaled
      end
    end

    def last_scaled=(time)
      if supported_cache?
        Rails.cache.write "heroku_autoscale:last_scaled", time
      else
        @last_scaled = time
      end
    end
  end
end
