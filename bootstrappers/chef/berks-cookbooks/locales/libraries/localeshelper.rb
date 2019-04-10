module Locales
  module Helper
    def current_locale
      cmd = Mixlib::ShellOut.new('locale').run_command
      Hash[cmd.stdout.split.map { |c| c.chomp.gsub('"', '').split('=') }]
    end

    def locales_available
      Mixlib::ShellOut.new('locale -a').run_command.stdout.split
    end

    def locale_pattern
      /(C|[a-z]*)(_[A-Z]*)?/
    end
  end
end
