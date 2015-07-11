require 'scrolls'

Scrolls.add_timestamp = true
Scrolls.global_context(app: 'banksclosedtoday', pid: Process.pid, thread: Thread.current.object_id)
