# frozen_string_literal: true

require_relative "../../omnievent/eventbrite/version"
require "omnievent/strategies/api"

module OmniEvent
  module Strategies
    # Strategy for listing events from Eventbrite
    class Eventbrite < OmniEvent::Strategies::API
      class Error < StandardError; end

      option :name, "eventbrite"
      option :organization_id, ""

      API_VERSION = "v3"

      def raw_events
        response = perform_request(path: request_path)
        events = response["events"]
        has_more_items = response["pagination"]["has_more_items"]

        while has_more_items
          response = perform_request(path: request_path, continuation: response["pagination"]["continuation"])
          events << response["events"]
          has_more_items = response["pagination"]["has_more_items"]
        end

        events
      end

      def event_hash(raw_event)
        data = {
          start_time: format_time(raw_event["start"]["utc"]),
          end_time: format_time(raw_event["end"]["utc"]),
          name: raw_event["name"]["text"],
          description: raw_event["description"]["text"],
          url: raw_event["url"]
        }

        metadata = {
          uid: raw_event["id"],
          status: convert_status(raw_event["status"]),
          created_at: format_time(raw_event["created"]),
          updated_at: format_time(raw_event["changed"])
        }

        metadata[:taxonomies] = raw_event["category"]["name"] if raw_event["category"]

        OmniEvent::EventHash.new(
          provider: name,
          data: data,
          metadata: metadata
        )
      end

      def request_url
        "https://www.eventbriteapi.com"
      end

      def request_path
        @request_path ||= begin
          path = "/#{API_VERSION}"

          # endpoint
          path += "/organizations/#{options.organization_id}/events/" if options.organization_id

          # params
          expansions = ["category"]
          path += "?expand=#{expansions.join(",")}" if expansions.any?

          path
        end
      end

      def request_headers
        { "Authorization" => "Bearer #{options.token}" }
      end

      def convert_status(raw_status)
        case raw_status
        when "draft"
          "draft"
        when "live", "started", "ended", "completed"
          "published"
        when "canceled"
          "cancelled"
        else
          "published"
        end
      end
    end
  end
end
