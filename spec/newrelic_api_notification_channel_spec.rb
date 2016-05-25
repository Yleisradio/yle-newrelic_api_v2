# encoding: UTF-8
require_relative '../lib/newrelic_api/newrelic_api_notification_channel'

RSpec.describe Yle::NewRelicApi::NotificationChannel do
  before(:each) do
    WebMock.disable_net_connect!
    notification_channel_response_page_1 = File.read('spec/mock_response_notification_channel_page_1.json')
    notification_channel_response_page_2 = File.read('spec/mock_response_notification_channel_page_2.json')
    user_response = File.read('spec/mock_response_user.json')

    stub_request(:get, %r{https://api.newrelic.com/v2/notification_channels.json.*(page=1)?})
      .to_return(status: 200, body: notification_channel_response_page_1,
                 headers: { 'Content-Type' => 'application/json',
                            'Link' => '<https://api.newrelic.com/v2/notification_channels.json?page=2>; rel="next", <https://api.newrelic.com/v2/notification_channels.json?page=2>; rel="last"' })

    stub_request(:get, %r{https://api.newrelic.com/v2/notification_channels.json.*page=2})
      .to_return(status: 200, body: notification_channel_response_page_2,
                 headers: { 'Content-Type' => 'application/json',
                            'Link' => '<https://api.newrelic.com/v2/notification_channels.json?page=1>; rel="first", <https://api.newrelic.com/v2/notification_channels.json?page=1>; rel="prev"' })

    stub_request(:get, %r{api.newrelic.com/v2/users.json})
      .to_return(status: 200, body: user_response,
                 headers: { 'Content-Type' => 'application/json' })

    @email = { 'name' => 'mock@example.local',
               'id' => 123466 }
    @webhook = { 'name' => 'Webhook',
                 'id' => 123467 }
    @group = { 'name' => 'Notification Group',
               'id' => 123468 }
    @pager_duty = { 'name' => 'PagerDuty',
                    'id' => 123469 }
    @hipchat = { 'name' => 'HipChat',
                 'id' => 123470 }
    @user = { 'name' => 'mock2@example.local',
              'id' => 123473 }

    @params = {
      'format' => 'JSON'
    }

    @api_key = '1234567890abcdef0987654321fedcba1234567890abcde'
    @client = Yle::NewRelicApi::NotificationChannel.new(@api_key)
    @client.get_all_pages(@params)
  end

  context 'with notification channel list' do
    it "returns the email's notification channel id" do
      id = @client.get_email_id(@email['name'])
      expect(id).to eq @email['id']
    end

    it "returns the webhook's notification channel id" do
      id = @client.get_webhook_id(@webhook['name'])
      expect(id).to eq @webhook['id']
    end

    it "returns the notification group's notification channel id" do
      id = @client.get_group_id(@group['name'])
      expect(id).to eq @group['id']
    end

    it "returns the PagerDuty's notification channel id" do
      id = @client.get_pager_duty_id(@pager_duty['name'])
      expect(id).to eq @pager_duty['id']
    end

    it "returns the HipChat's notification channel id" do
      id = @client.get_hipchat_id(@hipchat['name'])
      expect(id).to eq @hipchat['id']
    end

    it "returns the users's notification channel id" do
      id = @client.get_user_id(@user['name'])
      expect(id).to eq @user['id']
    end
  end
end
