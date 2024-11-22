unified_mode true

property :package,
        String,
        description: 'Name of the package to install.',
        default: node['kernel']['machine'] == 'x86_64' ? '7-Zip 19.00 (x64 edition)' : '7-Zip 19.00'

property :source,
        String,
        description: 'Source URL of the package to install.',
        default: node['kernel']['machine'] == 'x86_64' ? 'https://www.7-zip.org/a/7z1900-x64.msi' : 'https://www.7-zip.org/a/7z1900.msi'

property :checksum,
        String,
        description: 'Checksum for the downloaded pacakge.',
        default: node['kernel']['machine'] == 'x86_64' ? 'a7803233eedb6a4b59b3024ccf9292a6fffb94507dc998aa67c5b745d197a5dc' : 'b49d55a52bc0eab14947c8982c413d9be141c337da1368a24aa0484cbb5e89cd'

property :path,
        String,
        description: 'Optional: path to install 7zip to.'

action :install do
  windows_package new_resource.package do
    action :install
    source new_resource.source
    checksum new_resource.checksum unless new_resource.checksum.nil?
    options "INSTALLDIR=\"#{new_resource.path}\"" unless new_resource.path.nil?
  end
end

action :add_to_path do
  windows_path 'seven_zip' do
    action :add
    path new_resource.path || registry_path
  end
end

action :remove do
  windows_package new_resource.package do
    action :remove
  end
end

action_class do
  REG_PATH = 'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\7zFM.exe'.freeze

  def registry_path
    ::Win32::Registry::HKEY_LOCAL_MACHINE.open(REG_PATH, ::Win32::Registry::KEY_READ).read_s('Path')
  end
end
