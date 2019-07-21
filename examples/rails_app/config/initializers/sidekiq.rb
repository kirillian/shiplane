# frozen_string_literal: true

require 'shiplane/safe_build'

Shiplane::SafeBuild.wrap do
  require 'sidekiq'

  Sidekiq.configure_server do |config|
    config.redis = REDIS_CONFIG
  end

  Sidekiq.configure_client do |config|
    config.redis = REDIS_CONFIG
  end

  RedisInstance.instance
end
