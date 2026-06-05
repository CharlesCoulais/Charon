(module
  ;;LOGIC OPERATOR FUNCTIONS
  (func (export "or") (param $x i32) (param $y i32) (result i32)
    (select
      (select
        (i32.const 0)
        (i32.const 1)
        (i32.eqz (local.get $y))
      )
      (i32.const 1)
      (i32.eqz (local.get $x))
    )    
  )

  (func (export "and") (param $x i32) (param $y i32) (result i32)
    (select
      (i32.const 0)
      (select
        (i32.const 0)
        (i32.const 1)
        (i32.eqz (local.get $y))
      )
      (i32.eqz (local.get $x))
    )    
  )

  (func (export "not") (param $value i32) (result i32)
    (i32.eqz (local.get $value))
  )
)