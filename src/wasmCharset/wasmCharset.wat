(module
  ;; IMPORTS
  (import "js" "mem" (memory 1))
  (import "js" "logChar" (func $logChar (param i32)))
  (import "js" "logBool" (func $logBool (param i32)))

  ;; TYPES
  (type $pi32 (func (param $i i32)))
  (type $pi32ri32 (func (param i32) (result i32)))
  (type $pi32i32ri32 (func (param i32) (param i32) (result i32)))


  ;; LOG FUNCTIONS
  (func $logCharAt (export "logCharAt") (type $pi32)
    (call $getValueAt (local.get 0))
    call $logChar
  )

  ;; GET VALUE AT
  (func $getValueAt (param i32) (result i32)
    (i32.load8_u (local.get 0))
  )

  ;; IS STRING END
  (func $isStringEnd (param i32) (result i32)
    (i32.eqz (call $getValueAt (local.get 0)))
  )

  ;; INCREMENT
  (func $inz (param i32) (result i32)
    local.get 0
    i32.const 1
    i32.add
  )

  ;; CONTAINS
  (func (export "includes") (type $pi32ri32) (param $char i32) (result i32)
    (local $i i32)
    (local.set $i (i32.const 0))

    (i32.eqz (local.get $char))
    (if (then (return (i32.const 0))))
    
    (block $block
      (loop $loop
        (i32.eq (local.get $char) (call $getValueAt (local.get $i)))
        br_if $block

        (local.tee $i (call $inz (local.get $i)))
        (i32.eqz (call $isStringEnd))
        br_if $loop
      )
    )

    (i32.eq (local.get $char) (call $getValueAt (local.get $i)))
  )
)