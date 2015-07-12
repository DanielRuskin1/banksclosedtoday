# KeenService is used for metrics tracking; all requests are tracked with the KeenMetrics middleware.
class KeenService
  ###
  # This method takes in the below parameters, and uses them to track an action with Keen.
  # 1. action_name (required) - The name of the action (e.g. page_visit for a page visit).
  # 2. request (keyword arg) - The Rack::Request object associated with the action.
  # 3. tracking_params (keyword arg) - Parameters to send to Keen (e.g. the action's details).
  def self.track_action(action_name, request: nil, tracking_params: {})
    catch_and_handle_errors do
      # Log
      track(method: :track_action, status: :started, action_name: action_name, tracking_params: tracking_params)

      # Merge request params into tracking_params, if a request was provided.
      if request
        tracking_params = tracking_params.merge(generate_request_params(request))
      end

      # Schedule publishing if on production
      # Async publishing is used to avoid slowing down requests
      Keen.publish_async(action_name, tracking_params) if Rails.env.production?

      # Log
      track(method: :track_action, status: :completed, action_name: action_name, tracking_params: tracking_params)

      # Return true for success
      true
    end
  end

  # Helper method to generate Keen tracking params for a Rack::Request object.
  def self.generate_request_params(request)
    # Verify that request is valid
    fail ArgumentError, "Invalid parameter #{request}!" unless request.is_a?(Rack::Request)

    # Generate Keen params
    tracking_params = {}
    tracking_params[:request] = {}
    tracking_params[:request][:uuid] = request.uuid
    tracking_params[:request][:remote_ip] = request.remote_ip
    tracking_params[:request][:user_agent] = request.user_agent
    tracking_params[:request][:url] = request.url

    # Return generated params
    tracking_params
  end

  ###
  # Helper method to run a block, then take the following actions on exceptions
  # 1. Notify Rollbar
  # 2. Track on Scrolls
  # 3. Return false
  # As Keen tracking is non-critical, the above error handling will ensure that requests
  # are not interrupted due to errors.
  def self.catch_and_handle_errors
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
