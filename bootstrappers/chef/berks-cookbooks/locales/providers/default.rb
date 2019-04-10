include ::Locales::Helper

# Support whyrun
def whyrun_supported?
  true
end

action :add do
  new_resource.locales.each do |locale|
    if locale_available?(locale) || locale == 'C'
      Chef::Log.debug "#{ locale } already available - nothing to do."
    else
      converge_by("Add #{ locale }") do
        add_locale(locale)
      end
    end
  end
end

action :set do
  Chef::Log.error('Only set 1 locale') if new_resource.locales.count != 1

  locale = new_resource.locales[0]

  locales locale do
    action :add
  end

  converge_by("Set locale to #{ new_resource.locales }") do
    env_variables = %w(LANG LANGUAGE)
    env_variables << 'LC_ALL' if new_resource.lc_all

    env_variables.each do |env_var|
      ruby_block "update-locale #{env_var} #{locale}" do
        block { update_locale(env_var, locale) }
        only_if { ENV[env_var] != high_locale(locale) }
      end
    end
  end
end

def initialize(name, run_context = nil)
  super
  new_locales = Array(new_resource.locales).map { |l| l[locale_pattern] }
  @new_resource.locales(new_locales)
end

def parsed_locale(locale)
  # produce an Array of Hash like
  # 'fr_FR.UTF-8' give
  # {"locale"=>"fr_FR", "charmap"=>"UTF-8"}
  m = /^(?<locale>[\w@]*)\.?(?<charmap>.*)$/.match(locale)
  Hash[m.names.zip(m.captures)]
end

def locale_available?(locale)
  locales_available.include?(low_locale(locale))
end

def high_locale(locale)
  p = parsed_locale(locale)
  ret = p['locale']
  ret += '.' + p['charmap'].upcase unless p['charmap'].empty?
  ret
end

def low_locale(locale)
  p = parsed_locale(locale)
  ret = p['locale']
  ret += '.' + p['charmap'].downcase unless p['charmap'].empty?
  ret
end

def add_locale(locale)
  run_context.include_recipe 'locales::install'

  ruby_block "add locale #{locale}" do
    block do
      file = Chef::Util::FileEdit.new(node['locales']['locale_file'])
      line = "#{high_locale(locale)} #{new_resource.charmap}"
      file.insert_line_if_no_match(/^#{line}$/, line)
      file.write_file
    end
    notifies :run, 'execute[locale-gen]', :immediate
  end
end

def update_locale(variable, locale)
  cmd = "update-locale #{variable}=#{high_locale(locale)}"
  Mixlib::ShellOut.new(cmd).run_command
  ENV[variable] = locale
end
