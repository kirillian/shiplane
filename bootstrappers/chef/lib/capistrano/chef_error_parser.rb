module Shiplane
  class ChefErrorParser
    ERROR_LINE_REGEXP = /================================================================================/
    CHEF_ERRORS = [
      /ERROR: Exception handlers complete/,
      /FATAL: Chef::Exceptions::ChildConvergeError/,
    ]

    attr_accessor :error

    def initialize(error)
      @error = error
    end

    def lines
      @lines ||= error.message.split("\n")
    end

    def first_line
      @first_line ||= lines.index(lines.reverse_each.find{|line| line =~ ERROR_LINE_REGEXP }) || 0
    end

    def last_line
      @last_line ||= lines.index{|line| CHEF_ERRORS.any?{ |error| line =~ error } } || -1
    end

    def parse
      lines[first_line..last_line]
    end

    def self.parse(error)
      new(error).parse
    end
  end
end
