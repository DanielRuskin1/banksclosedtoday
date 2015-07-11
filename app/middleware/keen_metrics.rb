class KeenMetrics
  def initialize(app)
    @app = app
  end

  KEEN_REQUEST_ACTION_NAME = "page_visit"
  def call(env)
    # Get request
    request = Rack::Request.new(env)

    # Get Keen params
    keen_params = {}
    keen_params[:remote_ip] = request.ip
    keen_params[:user_agent] = request.user_agent
    keen_params[:request_path] = request.path

    # Notify Keen with params, if we're on production
    if Rails.env.production?
      begin
        Keen.publish_async(KEEN_REQUEST_ACTION_NAME, keen_params)
      rescue => e
        # Just notify Rollbar if an error occurs here
        # Keen tracking is non-critical - so we don't need to fail the entire request.
        Rollbar.error(e)
      end
    end

    # Finish call
    @app.call(env)
  end
end