require 'logger'

require_relative '../yle-newrelic_api_v2'

module Yle
  module NewRelicApi
    class Servers
      include Yle::NewRelicApi

      def initialize(api_key)
        @api_key = api_key
        @data = []
        @endpoint = URI('https://api.newrelic.com/v2/servers.json')
        @pages = nil
      end

      def servers
        servers = []
        @data.each do |d|
          j = JSON.parse(d)
          j['servers'].each do |s|
            servers << s['id']
          end
        end
        servers
      end

      def healthy?(server_id)
        @data.each do |d|
          j = JSON.parse(d)
          j['servers'].each do |s|
            return s['reporting'] if s['id'] == server_id
          end
        end
      end

      def delete_non_reporting(server_id)
        if !healthy?(server_id)
          endpoint = "https://api.newrelic.com/v2/servers/#{server_id}.json"
          if hostname(server_id).start_with?('ip-10-')
            puts "Deleting #{hostname(server_id)}"
            delete(endpoint)
          else
            require 'time'
            now = Time.new
            not_reported_for = ((now - Time.parse(last_reported(server_id))) / 60 / 60 / 24).round
            if not_reported_for > 5
              puts "Deleting #{hostname(server_id)} - not reported for #{not_reported_for} days"
              delete(endpoint)
            end
          end
        end
      end

      def last_reported(server_id)
        @data.each do |d|
          j = JSON.parse(d)
          j['servers'].each do |s|
            return s['last_reported_at'] if s['id'] == server_id
          end
        end
      end

      def hostname(server_id)
        @data.each do |d|
          j = JSON.parse(d)
          j['servers'].each do |s|
            return s['host'] if s['id'] == server_id
          end
        end
      end
    end
  end
end
