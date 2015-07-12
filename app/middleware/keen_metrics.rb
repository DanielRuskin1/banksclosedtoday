class KeenMetrics
  def initialize(app)
    @app = app
  end

  KEEN_REQUEST_ACTION_NAME = 'page_visit'
  def call(env)
    # Get request
    request = ActionDispatch::Request.new(env)

    # Track with Keen
    KeenService.track_action(KEEN_REQUEST_ACTION_NAME, request: request)

    # Finish call
    @app.call(env)
  end
end
