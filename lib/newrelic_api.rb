#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'yaml'

require_relative 'newrelic_api/newrelic_api_user'
require_relative 'newrelic_api/newrelic_api_notification_channel'
require_relative 'newrelic_api/newrelic_api_alert_policy'
require_relative 'newrelic_api/newrelic_api_servers'

module Yle
  module NewRelicApi
    def get(params = {})
      @endpoint.query = URI.encode_www_form(params)
      Net::HTTP.start(@endpoint.host, @endpoint.port,
                      use_ssl: @endpoint.scheme == 'https') do |http|
        request = Net::HTTP::Get.new @endpoint
        request.add_field('X-Api-Key', @api_key)
        response = http.request request
        # raise HTTP Error, if response code is not 2XX
        response.value
        process_response_body(response)
      end
    end

    def get_all_pages(params = {})
      count = pages(params)
      page = 1
      while page <= count do
        params['page'] = page
        get(params)
        page += 1
      end
    end

    def pages(params = {})
      response = nil
      @endpoint.query = URI.encode_www_form(params)
      Net::HTTP.start(@endpoint.host, @endpoint.port,
                      use_ssl: @endpoint.scheme == 'https') do |http|
        request = Net::HTTP::Get.new @endpoint
        request.add_field('X-Api-Key', @api_key)
        response = http.request request
        # raise HTTP Error, if response code is not 2XX
        response.value
      end
      last_page(response)
    end

    def put(params, endpoint)
      uri = URI("https://api.newrelic.com/v2/#{endpoint}.json")
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Put.new uri
        request.add_field('X-Api-Key', @api_key)
        request.add_field('Content-Type', 'application/json')
        request.body = params.to_json
        response = http.request request
        # raise HTTP Error, if response code is not 2XX
        response.value
      end
    end

    def clear
      @data.clear
    end

    def last_page(response)
      return 1 unless response.key?('Link')
      m = response['Link'].match(/<http.*\?page=(\d+)>; rel="last"/)
      return 1 unless m
      m[1].to_i
    end

    def get_next_page_number(response)
      m = response['Link'].match(/<http.*\?page=(\d+)>; rel="next"/)
      m[1].to_i
    end

    def delete(endpoint)
      uri = URI(endpoint)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Delete.new uri
        request.add_field('X-Api-Key', @api_key)
        response = http.request request
        # raise HTTP Error, if response code is not 2XX
        response.value
      end
    end

    private

    def process_response_body(response)
      # check that response has a body
      if response.class.body_permitted?
        @data << response.body
      else
        raise "Empty response from New Relic API:\n\n #{response}"
      end
    end
  end
end
