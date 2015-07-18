# Middleware to track all requests with KeenService
class KeenMetrics
  def initialize(app)
    @app = app
  end

  def call(env)
    # Get request
    request = ActionDispatch::Request.new(env)

    # Track with Keen
    KeenService.track_action(:page_visit, request: request)

    # Finish call
    @app.call(env)
  end
end
