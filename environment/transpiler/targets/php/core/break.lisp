(fn break (msg)
  (error_log msg)
  (%princ msg)
  (invoke-debugger)
  (tre_backtrace "*BREAK*"))
