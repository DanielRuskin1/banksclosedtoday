require 'spec_helper'

# As Keen is only called on production, there's not too much we can test here (only peripherals).
describe KeenService do
  before do
    # Init valid request
    @valid_request = ActionDispatch::TestRequest.new
  end

  describe '#track_action' do
    # Helper method to get expected params for a request
    def expected_request_params
      {
        request: {
          uuid: @valid_request.uuid,
          remote_ip: @valid_request.remote_ip,
          user_agent: @valid_request.user_agent,
          url: @valid_request.url
        }
      }
    end

    before do
      # Spy on Scrolls during these test
      allow(Scrolls).to receive(:log).and_call_original
    end

    describe 'logging' do
      before do
        # Make sure Rollbar is not notified during these tests
        expect(Rollbar).to_not receive(:error)
      end

      it 'should log with the correct params when a request object is passed' do
        # Call method with a valid request; make sure a successful result is returned
        expect(KeenService.track_action(:page_visit, request: @valid_request)).to eq(true)

        # Verify started logging
        expected_started_log = {
          method: :track_action,
          status: :started,
          action_name: :page_visit,
          tracking_params: {},
          at: 'KeenService'
        }
        expect(Scrolls).to have_received(:log).with(**expected_started_log)

        # Verify completed logging
        expected_completed_log = {
          method: :track_action,
          status: :completed,
          action_name: :page_visit,
          tracking_params: expected_request_params,
          at: 'KeenService'
        }
        expect(Scrolls).to have_received(:log).with(**expected_completed_log)
      end

      it 'should log with the correct params when tracking_params are passed' do
        # Call method with a valid request; make sure a successful result is returned
        expect(KeenService.track_action(:page_visit, tracking_params: { foo: 'bar' })).to eq(true)

        # Verify started logging
        expected_started_log = {
          method: :track_action,
          status: :started,
          action_name: :page_visit,
          tracking_params: { foo: 'bar' },
          at: 'KeenService'
        }
        expect(Scrolls).to have_received(:log).with(**expected_started_log)

        # Verify completed logging
        expected_completed_log = {
          method: :track_action,
          status: :completed,
          action_name: :page_visit,
          tracking_params: { foo: 'bar' },
          at: 'KeenService'
        }
        expect(Scrolls).to have_received(:log).with(**expected_completed_log)
      end

      it 'should log with the correct params when no params are passed' do
        # Call method with a valid request; make sure a successful result is returned
        expect(KeenService.track_action(:page_visit)).to eq(true)

        # Verify started logging
        expected_started_log = {
          method: :track_action,
          status: :started,
          action_name: :page_visit,
          tracking_params: {},
          at: 'KeenService'
        }
        expect(Scrolls).to have_received(:log).with(**expected_started_log)

        # Verify completed logging
        expected_completed_log = {
          method: :track_action,
          status: :completed,
          action_name: :page_visit,
          tracking_params: {},
          at: 'KeenService'
        }
        expect(Scrolls).to have_received(:log).with(**expected_completed_log)
      end
    end

    describe 'error handling' do
      before do
        # Spy on Rollbar here
        allow(Rollbar).to receive(:error).and_call_original
      end

      it 'should rescue any exceptions and log correctly' do
        # Call the method with an invalid parameter (a String)
        # Make sure an unsuccessful result is returned
        expect(KeenService.track_action(:page_visit, request: 'foo')).to eq(false)

        # Verify started logging
        expected_started_log = {
          method: :track_action,
          status: :started,
          action_name: :page_visit,
          tracking_params: {},
          at: 'KeenService'
        }
        expect(Scrolls).to have_received(:log).with(**expected_started_log)

        # Make sure Rollbar was notified with an ArgumentError
        expect(Rollbar).to have_received(:error).with(instance_of(ArgumentError))
      end
    end
  end
end
