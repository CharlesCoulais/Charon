(module
  (import "export" "log" (func $log (param i32) (param i32)))


  (func (export "logBool") (param $i i32)
    i32.const 1
    local.get 0
    call $log
  )

  (func (export "logI32") (param $i i32)
    i32.const 2
    local.get 0
    call $log
  )
  
  (func (export "logChar") (param $i i32)
    i32.const 3
    local.get 0
    call $log
  )
)