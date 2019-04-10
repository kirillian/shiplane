require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin'
  end
end

describe 'Locales' do

  it 'installs the default locale en_US.utf8' do
    expect(command('locale -a | grep en_US.utf8')).to return_stdout('en_US.utf8')
  end

end
