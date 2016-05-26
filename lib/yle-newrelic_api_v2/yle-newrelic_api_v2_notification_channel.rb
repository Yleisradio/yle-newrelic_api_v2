require_relative '../yle-newrelic_api_v2'
require_relative 'yle-newrelic_api_v2_user'

module Yle
  module NewRelicApi
    class NotificationChannel
      include Yle::NewRelicApi

      def initialize(api_key)
        @api_key = api_key
        @data = []
        @endpoint = URI('https://api.newrelic.com/v2/notification_channels.json')
      end

      def get_group_id(name)
        matches = get_id(name)
        if matches.nil?
          raise "Did not find any notification groups with name #{name}"
        elsif matches.length > 1
          raise "Found multiple matches for notification group name: #{matches}"
        else
          return matches[0]['id']
        end
      end

      def get_email_id(name)
        matches = get_id_for_email(name)
        if matches.empty?
          raise "Did not find any emails with name #{name}"
        elsif matches.length > 1
          raise "Found multiple matches for email: #{matches}"
        else
          return matches[0]['id']
        end
      end

      def get_webhook_id(name)
        matches = get_id(name)
        if matches.nil?
          raise "Did not find any webhooks with name #{name}"
        elsif matches.length > 1
          raise "Found multiple matches for webhook: #{matches}"
        else
          return matches[0]['id']
        end
      end

      def get_pager_duty_id(name)
        matches = get_id_for_pagerduty(name)
        if matches.nil?
          raise "Did not find any PagerDuty channels with name #{name}"
        elsif matches.length > 1
          raise "Found multiple matches for PagerDuty: #{matches}"
        else
          return matches[0]['id']
        end
      end

      def get_hipchat_id(name)
        matches = get_id(name)
        if matches.nil?
          raise "Did not find any HipChat channels with name #{name}"
        elsif matches.length > 1
          raise "Found multiple matches for HipChat: #{matches}"
        else
          return matches[0]['id']
        end
      end

      def get_user_id(email)
        params = {
          'filter[email]' => email,
          'format' => 'JSON'
        }

        client = Yle::NewRelicApi::User.new(@api_key)
        client.get(params)
        user_id = client.get_user_id(email)
        user_notification_channel_id = get_id_for_user(user_id)
        user_notification_channel_id
      end

      private

      def get_id(name)
        hits = []
        @data.each do |d|
          j = JSON.parse(d)
          matches = j['notification_channels'].select { |group| group['name'] == name }
          hits << matches unless matches.empty?
        end
        hits[0]
      end

      def get_id_for_email(email)
        hits = []
        @data.each do |d|
          j = JSON.parse(d)
          matches = j['notification_channels'].select { |group| group['email'] == email }
          hits << matches unless matches.empty?
        end
        hits[0]
      end

      def get_id_for_pagerduty(service)
        hits = []
        @data.each do |d|
          j = JSON.parse(d)
          matches = j['notification_channels'].select { |group| group['service'] == service }
          hits << matches unless matches.empty?
        end
        hits[0]
      end

      def get_id_for_user(user_id)
        @data.each do |d|
          j = JSON.parse(d)
          j['notification_channels'].each do |c|
            if c.key?('links')
              if c['links'].key?('user')
                if c['links']['user'] == user_id
                  # found user id, return notification channel id
                  return c['id']
                end
              end
            end
          end
        end
      end
    end
  end
end
