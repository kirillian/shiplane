unified_mode true

property :path,
        String,
        name_property: true,
        description: 'Path to extract the archive.'

property :source,
        String,
        description: 'Source archive location.'

property :overwrite,
        [true, false],
        default: false,
        description: 'Whether to overwrite the destination files.'

property :checksum,
        String,
        description: 'The checksum for the downloaded file.'

property :timeout,
        Integer,
        default: 600,
        description: 'Extract timeout in seconds.'

action :extract do
  directory new_resource.path

  local_source = cached_file(new_resource.source, new_resource.checksum)

  overwrite_file = new_resource.overwrite ? ' -y' : ' -aos'

  cmd = "\"#{seven_zip_exe}\" x"
  cmd << overwrite_file
  cmd << " -o\"#{Chef::Util::PathHelper.cleanpath(new_resource.path)}\""
  cmd << " \"#{local_source}\""

  Chef::Log.debug(cmd)

  execute "extracting #{new_resource.source}" do
    command cmd
    timeout new_resource.timeout
  end
end

action_class do
  # require 'chef/mixin/shell_out'
  # include Chef::Mixin::ShellOut

  def seven_zip_exe
    path = seven_zip_exe_from_registry
    Chef::Log.debug("Using 7-zip home: #{path}")
    Chef::Util::PathHelper.cleanpath(::File.join(path, '7z.exe'))
  end

  def seven_zip_exe_from_registry
    require 'win32/registry'
    # Read path from recommended Windows App Paths registry location
    # docs: https://msdn.microsoft.com/en-us/library/windows/desktop/ee872121
    ::Win32::Registry::HKEY_LOCAL_MACHINE.open(
      'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe',
      ::Win32::Registry::KEY_READ
    ).read_s('Path')
  end

  # if a file is local it returns a windows friendly path version
  # if a file is remote it caches it locally
  def cached_file(source, checksum = nil)
    if source =~ %r{^(file|ftp|http|https):\/\/}
      uri = as_uri(source)
      cache_file_path = "#{Chef::Config[:file_cache_path]}/#{::File.basename(::CGI.unescape(uri.path))}"
      Chef::Log.debug("Caching a copy of file #{source} at #{cache_file_path}")

      remote_file cache_file_path do
        source source
        backup false
        checksum checksum unless checksum.nil?
      end
    else
      cache_file_path = source
    end

    Chef::Util::PathHelper.cleanpath(cache_file_path)
  end

  def as_uri(source)
    URI.parse(source)
  rescue URI::InvalidURIError
    Chef::Log.warn("#{source} was an invalid URI. Trying to escape invalid characters")
    URI.parse(URI.escape(source))
  end
end
