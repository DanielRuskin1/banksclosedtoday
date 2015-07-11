require 'spec_helper'

# As Keen is only called on production, there's not too much we can test here (only peripherals).
describe KeenService do
  before do
    # Init valid request
    @valid_request = ActionDispatch::TestRequest.new
  end

  describe "#track_request" do
    # Helper method to verify that the appropriate logging occurred.
    def verify_logging(type)
      # Get expected Keen params - this is used in a few of the options below
      expected_keen_params = {
        uuid: @valid_request.uuid,
        remote_ip: @valid_request.remote_ip,
        user_agent: @valid_request.user_agent,
        request_url: @valid_request.url,
      }

      # Get expected params
      case type
      when :started
        expected_params = {
          request_uuid: @valid_request.uuid,
          method: :track_request,
          status: :started,
        }
      when :completed
        expected_params = {
          request_uuid: @valid_request.uuid,
          method: :track_request,
          status: :success,
          keen_params: expected_keen_params,
        }
      when :failure_with_invalid_parameter
        expected_params = {
          request_uuid: nil,
          method: :track_request,
          status: :failed,
          keen_params: nil,
        }
      when :failure_with_valid_parameter
        expected_params = {
          request_uuid: @valid_request.uuid,
          method: :track_request,
          status: :failed,
          keen_params: expected_keen_params,
        }
      else
        raise NotImplementedError, "Unknown type #{type}!"
      end

      # Add "at" parameter to the expected_params
      expected_params.merge!(at: "KeenService")

      # Verify that logging occurred
      expect(Scrolls).to have_received(:log).with(**expected_params)
    end

    # Helper method to spy on a class
    def spy(type)
      case type
      when :rollbar
        allow(Rollbar).to receive(:error)
      when :scrolls
        allow(Scrolls).to receive(:log)
      end
    end

    describe "logging" do
      it "should log with the correct params" do
        # Spy on rollbar and scrolls during this test
        spy(:rollbar)
        spy(:scrolls)

        # Call method with a valid request; make sure a successful result is returned
        expect(KeenService.track_request(@valid_request)).to eq(true)

        # Verify started logging
        verify_logging(:started)

        # Verify completed logging
        verify_logging(:completed)

        # Make sure Rollbar was not notified during this test
        expect(Rollbar).to_not have_received(:error)
      end
    end

    describe "error handling" do
      it "should rescue any exceptions and log correctly" do
        # Spy on rollbar and scrolls during this test
        spy(:rollbar)
        spy(:scrolls)

        # Call the method with an invalid parameter (a String)
        # Make sure an unsuccessful result is returned
        expect(KeenService.track_request("foo")).to eq(false)

        # Verify failure logging
        verify_logging(:failure_with_invalid_parameter)

        # Make sure Rollbar was notified with an ArgumentError
        expect(Rollbar).to have_received(:error).with(instance_of(ArgumentError))
      end

      it "should also log with keen_params when available" do
        # Spy on rollbar and scrolls during this test
        spy(:rollbar)
        spy(:scrolls)

        # Stub the successful logging to raise an exception
        allow(Scrolls).to receive(:log).with(hash_including(status: :success)) do
          raise ArgumentError, "Success is impossible."
        end

        # Call the method with a valid request
        # Make sure an unsuccessful result is returned
        expect(KeenService.track_request(@valid_request)).to eq(false)

        # Verify failure logging
        verify_logging(:failure_with_valid_parameter)

        # Make sure Rollbar was notified with the ArgumentError raised above
        expect(Rollbar).to have_received(:error).with(instance_of(ArgumentError))
      end
    end
  end
end