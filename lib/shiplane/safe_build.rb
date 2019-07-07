module Shiplane
  class SafeBuild
    def self.wrap
      return if ENV['SHIPLANE_BUILDING'] == 'true'
      yield
    end
  end
end
