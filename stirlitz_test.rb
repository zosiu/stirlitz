require 'cuba/test'
require './stirlitz'

scope do
  test 'Homepage' do
    get '/'
    follow_redirect!

    assert_equal 200, last_response.status
  end
end
