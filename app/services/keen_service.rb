# KeenService is used for metrics tracking; all requests are tracked with the KeenMetrics middleware.
class KeenService
  ###
  # This method takes in a Rack::Request, then publishes it to Keen for metrics tracking.
  # Note that the actual Keen request will only occur on production.
  # Non-production environments will be skipped.
  KEEN_REQUEST_ACTION_NAME = "page_visit"
  def self.track_request(request)
    # Verify that request is valid
    raise ArgumentError, "Invalid parameter #{request}!" unless request.is_a?(Rack::Request)

    # Log
    request_uuid = request.uuid
    track(request_uuid: request_uuid, method: :track_request, status: :started)

    # Get Keen params
    keen_params = {}
    keen_params[:request_uuid] = request.uuid
    keen_params[:request_remote_ip] = request.remote_ip
    keen_params[:request_user_agent] = request.user_agent
    keen_params[:request_url] = request.url

    # Schedule publishing if we're on production
    # Async publishing is used to avoid slowing down requests
    Keen.publish_async(KEEN_REQUEST_ACTION_NAME, keen_params) if Rails.env.production?

    # Log
    track(request_uuid: request_uuid, method: :track_request, status: :success, keen_params: keen_params)

    # Return true for success
    true
  rescue => e
    # If any requests occur here, just notify Rollbar and log for now.
    # Keen tracking is non-critical, so there's no need to fail the entire request.
    Rollbar.error(e)

    # Log
    track(request_uuid: request_uuid, method: :track_request, status: :failed, keen_params: keen_params)

    # Return false for failure
    false
  end

  # Helper method to log requests to KeenService requests.
  def self.track(**params)
    # Log with added "at" indicator
    Scrolls.log({at: "KeenService"}.merge(params))
  end
end
