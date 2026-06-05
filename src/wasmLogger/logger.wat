(module
  (import "export" "log" (func $log (param i32) (param i32)))
  (import "export" "logRef" (func $logRef (param externref)))


  (func (export "logBool") (param i32)
    i32.const 1
    local.get 0
    call $log
  )

  (func (export "logI32") (param i32)
    i32.const 2
    local.get 0
    call $log
  )
  
  (func (export "logChar") (param i32)
    i32.const 3
    local.get 0
    call $log
  )

  (func (export "logStart") (param i32)
    i32.const 4
    local.get 0
    call $log
  )
  (func (export "logEnd") (param i32)
    i32.const 5
    local.get 0
    call $log
  )

  (func (export "logRef") (param externref)
    local.get 0
    call $logRef
  )
)