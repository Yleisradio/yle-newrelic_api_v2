require_relative '../lib/yle-newrelic_api_v2/yle-newrelic_api_v2_user'

RSpec.describe Yle::NewRelicApi::User do
  before(:each) do
    WebMock.disable_net_connect!
    user_response = File.read('spec/mock_response_user.json')

    stub_request(:get, %r{api.newrelic.com/v2/users.json})
      .to_return(status: 200, body: user_response,
                 headers: { 'Content-Type' => 'application/json' })

    @user = { 'name' => 'mock@example.local',
              'id' => 123472 }

    @params = {
      'filter[email]' => @user['name'],
      'format' => 'JSON'
    }
    @api_key = '1234567890abcdef0987654321fedcba1234567890abcde'
    @client = Yle::NewRelicApi::User.new(@api_key)
    @client.get_all_pages(@params)
  end

  context 'with email address as' do
    it 'returns the user id' do
      user_id = @client.get_user_id(@user['name'])
      expect(user_id).to eq @user['id']
    end
  end
end
