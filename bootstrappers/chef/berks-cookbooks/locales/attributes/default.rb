case node['platform_family']
when 'debian'
  default['locales']['packages'] = ['locales']
else
  default['locales']['packages'] = []
end

case node['platform']
when 'ubuntu'
  default['locales']['locale_file'] = '/var/lib/locales/supported.d/local'
else
  default['locales']['locale_file'] = '/etc/locale.gen'
end

default['locales']['default'] = 'en_US.utf8'
