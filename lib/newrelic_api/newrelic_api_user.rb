require_relative '../newrelic_api'

module Yle
  module NewRelicApi
    class User
      include Yle::NewRelicApi

      def initialize(api_key)
        @api_key = api_key
        @data = []
        @endpoint = URI('https://api.newrelic.com/v2/users.json')
      end

      def get_user_id(email)
        matches = get_id_by_email(email)
        if matches.empty?
          raise "Did not find any users with email #{email}"
        elsif matches.length > 1
          raise "Found multiple matches for email: #{matches}"
        else
          return matches[0]['id']
        end
      end

      private

      def get_id_by_email(email)
        @data.each do |d|
          j = JSON.parse(d)
          matches = j['users'].select { |user| user['email'] == email }
          return matches
        end
      end
    end
  end
end
