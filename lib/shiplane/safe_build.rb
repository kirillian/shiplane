module Shiplane
  class SafeBuild
    def self.wrap
      return if ENV['SHIPLANE'] == 'building'
      yield
    end
  end
end
