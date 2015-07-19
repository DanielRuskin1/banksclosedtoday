require 'scrolls'

Scrolls.init(
  timestamp: true,
  global_context: {
    app: 'banksclosedtoday',
    pid: Process.pid,
    thread: Thread.current.object_id
  }
)
