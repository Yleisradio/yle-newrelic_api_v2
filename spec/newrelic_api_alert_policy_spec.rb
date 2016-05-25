require 'yaml'
require 'webmock/rspec'
require_relative '../lib/newrelic_api/newrelic_api_alert_policy'

RSpec.describe Yle::NewRelicApi::AlertPolicy do
  before(:each) do
    WebMock.disable_net_connect!
    alert_policy_response = File.read('spec/mock_response_alert_policy.json')
    notification_channel_response_page_1 = File.read('spec/mock_response_notification_channel_page_1.json')
    notification_channel_response_page_2 = File.read('spec/mock_response_notification_channel_page_2.json')
    user_response = File.read('spec/mock_response_user.json')

    stub_request(:get, %r{https://api.newrelic.com/v2/alert_policies.json.*})
      .to_return(status: 200, body: alert_policy_response,
                 headers: { 'Content-Type' => 'application/json' })

    stub_request(:put, %r{https://api.newrelic.com/v2/alert_policies.*})
      .to_return(status: 200, body: '', headers: {})

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

    @alert_policy_id = 123456
    @email = { 'name' => 'mock@example.local',
               'id' => 123466 }

    file_path = File.expand_path('policy.yml', File.dirname(__FILE__))
    @config = YAML.load_file(file_path)

    @alert_policies_params = {
      'filter[name]' => @config['name'],
      'filter[type]' => 'server',
      'filter[enabled]' => true,
      'format' => 'JSON'
    }
    @api_key = '1234567890abcdef0987654321fedcba1234567890abcde'
    @client = Yle::NewRelicApi::AlertPolicy.new(@api_key)
    @client.get_all_pages(@alert_policies_params)
  end

  context 'with test alert policy' do
    it 'returns the alert policy in JSON' do
      policy = @client.get_alert_policy(@alert_policy_id)
      expect(policy['name']).to eq @config['name']
      expect(policy['conditions']).not_to be_empty
    end

    it 'returns the alert policy id' do
      id = @client.get_alert_policy_id(@config['name'])
      expect(id).to eq @alert_policy_id
    end

    it 'generates updated alert policy' do
      policy = @client.generate_alert_policy(@config, @alert_policy_id)
      expect(policy['conditions'][0]['threshold']).to eq 66
      expect(policy['conditions'][0]['trigger_minutes']).to eq 10
      expect(policy['links']['notification_channels'][0]).to eq @email['id']
    end

    it 'updates the alert policy to New Relic' do
      test_config = @config
      test_config['conditions']['disk_io']['caution']['threshold'] = 77

      alert_policy = {
        'id' => @alert_policy_id,
        'alert_policy' => @client.generate_alert_policy(test_config, @alert_policy_id),
        'format' => 'JSON'
      }
      @client.put(alert_policy, "alert_policies/#{@alert_policy_id}")
      @client.clear
      @client.get(@alert_policies_params)
      test_policy = @client.get_alert_policy(@alert_policy_id)
      expect(test_policy['conditions'][0]['threshold']).to eq 77
    end
  end
end
