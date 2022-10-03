# frozen_string_literal: true

RSpec.describe OmniEvent::Eventbrite do
  let(:events_json) { File.read(File.join(File.expand_path("..", __dir__), "fixtures", "events.json")) }
  let(:url) { "https://www.eventbriteapi.com" }
  let(:version) { OmniEvent::Strategies::Eventbrite::API_VERSION }
  let(:path) { "organizations/12345/events/?expand=category" }

  before do
    OmniEvent::Builder.new do
      provider :eventbrite, { token: "12345" }
    end
  end

  describe "list_events" do
    before do
      stub_request(:get, "#{url}/#{version}/#{path}")
        .with(headers: { "Authorization" => "Bearer 12345" })
        .to_return(body: events_json, headers: { "Content-Type" => "application/json" })
    end

    it "returns an event list" do
      events = OmniEvent.list_events(:eventbrite, organization_id: "12345")

      expect(events.size).to eq(1)
      expect(events).to all(be_kind_of(OmniEvent::EventHash))
    end

    it "returns valid events" do
      events = OmniEvent.list_events(:eventbrite, organization_id: "12345")

      expect(events.size).to eq(1)
      expect(events).to all(be_valid)
    end

    it "returns events with metadata" do
      events = OmniEvent.list_events(:eventbrite, organization_id: "12345")

      expect(events.size).to eq(1)
      expect(events.first.metadata.created_at).to eq("2022-09-27T09:14:04Z")
    end
  end
end
