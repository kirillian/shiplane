require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin'
  end
end

describe 'Locales' do

  it 'installs the expected locale fr_FR.utf8' do
    expect(command('locale -a | grep fr_FR.utf8')).to return_stdout('fr_FR.utf8')
  end

  it 'installs the expected locale fr_BE.utf8' do
    expect(command('locale -a | grep fr_BE.utf8')).to return_stdout('fr_BE.utf8')
  end

  it 'installs the expected locale fr_CA.utf8' do
    expect(command('locale -a | grep fr_CA.utf8')).to return_stdout('fr_CA.utf8')
  end

end
