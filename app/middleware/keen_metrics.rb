class KeenMetrics
  def initialize(app)
    @app = app
  end

  def call(env)
    # Get request
    request = ActionDispatch::Request.new(env)

    # Track with Keen
    KeenService.track_request(request)

    # Finish call
    @app.call(env)
  end
end