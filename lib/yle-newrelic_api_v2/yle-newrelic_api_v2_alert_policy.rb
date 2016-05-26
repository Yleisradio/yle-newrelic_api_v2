require_relative '../yle-newrelic_api_v2'
require_relative 'yle-newrelic_api_v2_notification_channel'

module Yle
  module NewRelicApi
    class AlertPolicy
      include Yle::NewRelicApi

      def initialize(api_key)
        @api_key = api_key
        @data = []
        @endpoint = URI('https://api.newrelic.com/v2/alert_policies.json')
      end

      def get_alert_policy_id(name)
        hits = []
        @data.each do |d|
          j = JSON.parse(d)
          matches = j['alert_policies'].select { |policy| policy['name'] == name }
          hits << matches unless matches.empty?
        end
        hits[0][0]['id']
      end

      def get_alert_policy(policy_id)
        hits = []
        @data.each do |d|
          j = JSON.parse(d)
          matches = j['alert_policies'].select { |policy| policy['id'] == policy_id }
          hits << matches unless matches.empty?
        end
        hits[0][0]
      end

      def generate_alert_policy(config, policy_id)
        policy = get_alert_policy(policy_id)

        config['conditions'].each do |item|
          policy['conditions'].each do |alert|
            update_alert(item, alert)
          end
        end

        update_notification_channel(policy, config)
        policy
      end

      private

      def update_alert(item, alert)
        type = item[0]

        if alert['type'] == 'server_downtime' && type == 'server_downtime'
          downtime = item[1]['downtime']
          alert['trigger_minutes'] = downtime['trigger_minutes']
          alert['enabled'] = downtime['enabled']
        elsif alert['type'] == type
          critical = item[1]['critical']
          caution = item[1]['caution']

          if alert['severity'] == 'critical'
            alert['threshold'] = critical['threshold']
            alert['trigger_minutes'] = critical['trigger_minutes']
          elsif alert['severity'] == 'caution'
            alert['threshold'] = caution['threshold']
            alert['trigger_minutes'] = caution['trigger_minutes']
          else
            raise "Unknown severity level #{alert['severity']}"
          end
        end
      end

      def update_notification_channel(policy, config)
        notification_channels_params = { 'format' => 'JSON' }
        channel_client = Yle::NewRelicApi::NotificationChannel.new(@api_key)
        channel_client.get_all_pages(notification_channels_params)

        # empty notification channels
        policy['links']['notification_channels'].clear

        config['notification_channels'].each do |item|
          type = item[0]
          values = item[1]

          case type
          when 'email'
            values.each do |v|
              policy['links']['notification_channels'] << channel_client.get_email_id(v)
            end
          when 'webhook'
            values.each do |v|
              policy['links']['notification_channels'] << channel_client.get_webhook_id(v)
            end
          when 'notification_group'
            values.each do |v|
              policy['links']['notification_channels'] << channel_client.get_group_id(v)
            end
          when 'pager_duty'
            values.each do |v|
              policy['links']['notification_channels'] << channel_client.get_pager_duty_id(v)
            end
          when 'hipchat'
            values.each do |v|
              policy['links']['notification_channels'] << channel_client.get_hipchat_id(v)
            end
          when 'user'
            values.each do |v|
              policy['links']['notification_channels'] << channel_client.get_user_id(v)
            end
          else
            raise "Unknown notification channel type #{type}"
          end
        end
        policy
      end
    end
  end
end
