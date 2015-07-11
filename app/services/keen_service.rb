# KeenService is used for metrics tracking; all requests are tracked with the KeenMetrics middleware.
class KeenService
  ###
  # This method takes in a Rack::Request, then publishes it to Keen for metrics tracking.
  # Note that the actual Keen request will only occur on production.
  # Non-production environments will be skipped.
  KEEN_REQUEST_ACTION_NAME = 'page_visit'
  def self.track_request(request)
    catch_and_handle_errors(:track_request) do
      # Log
      track(method: :track_request, status: :started)

      # Verify that request is valid
      fail ArgumentError, "Invalid parameter #{request}!" unless request.is_a?(Rack::Request)

      # Generate Keen params
      tracking_params = {}
      tracking_params[:request_uuid] = request.uuid
      tracking_params[:request_remote_ip] = request.remote_ip
      tracking_params[:request_user_agent] = request.user_agent
      tracking_params[:request_url] = request.url

      # Track on Keen
      track_action(KEEN_REQUEST_ACTION_NAME, tracking_params)
    end
  end

  def self.track_action(action_name, tracking_params)
    catch_and_handle_errors(:track_action) do
      # Log
      track(method: :track_action, status: :started, action_name: action_name, tracking_params: tracking_params)

      # Schedule publishing if on production
      # Async publishing is used to avoid slowing down requests
      Keen.publish_async(action_name, tracking_params) if Rails.env.production?

      # Log
      track(method: :track_action, status: :completed, action_name: action_name, tracking_params: tracking_params)

      # Return true for success
      true
    end
  end

  ###
  # Helper method to run a block, then take the following actions on exceptions
  # 1. Notify Rollbar
  # 2. Track on Scrolls
  # 3. Return false
  # As Keen tracking is non-critical, the above error handling will ensure that requests
  # are not interrupted due to errors.
  def self.catch_and_handle_errors(_method_name)
    yield
  rescue => e
    # Rollbar
    Rollbar.error(e)

    # Return
    false
  end

  # Helper method to log requests to KeenService requests.
  def self.track(**params)
    # Log with added "at" indicator
    Scrolls.log({ at: 'KeenService' }.merge(params))
  end
end
