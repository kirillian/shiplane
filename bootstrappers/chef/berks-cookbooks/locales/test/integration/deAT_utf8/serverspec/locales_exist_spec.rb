require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
  c.before :all do
    c.path = '/sbin:/usr/sbin'
  end
end

describe 'Locales' do

  it 'installs the expected locale de_AT.utf8' do
    expect(command('locale -a | grep de_AT.utf8')).to return_stdout('de_AT.utf8')
  end

end
