module Shiplane
  class SafeBuild
    def self.wrap
      return if ENV['SHIPLANE'] == 'running'
      yield
    end
  end
end
