# frozen_string_literal: true
require 'shiplane/safe_build'
require 'shiplane/safe_yaml_loading'

Shiplane::SafeBuild.wrap do
  redis_yaml_file = "config/redis.yml"

  raise "Redis config missing or incorrect." unless File.exist?(redis_yaml_file)

  REDIS_CONFIG = Shiplane::SafeYamlLoading.load(ERB.new(File.read(redis_yaml_file)).result)[Rails.env].symbolize_keys!

  class RedisInstance
    include Singleton

    def self.redis
      @redis ||= Redis.new(REDIS_CONFIG)
    end
  end
end
