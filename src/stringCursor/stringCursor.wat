(module
  ;; IMPORTS
  (import "js" "mem" (memory 1))
  (import "js" "slice" (func $js.slice (param i32) (param i32) (result externref)))
  (import "js" "logCursor" (func $js.logCursor (param i32) (param i32)))


  ;; TYPES
  (type $int (func (result i32)))

  ;; CURSOR
  (global $cursor (mut i32) (i32.const 1))
  ;; SAVED CURSOR POSITION
  (global $saved (mut i32) (i32.const 0))
  ;; SAVED CHAR
  (global $savedChar (mut i32) (i32.const 0))
  ;; SELECTION
  (global $selection.start (mut i32) (i32.const 0))
  (global $selection.end (mut i32) (i32.const 0))

  ;; INIT (to call when want to re-run with same or new string)
  (func (export "init")
    (global.set $cursor (i32.const 1))
    (global.set $saved (i32.const 0))
    (global.set $savedChar (i32.const 0))
    (global.set $selection.start (i32.const 0))
    (global.set $selection.end (i32.const 0))
  )
  
  ;; CURSOR SETTER
  (func $cursor.set (export "cursor.set") (param i32)
    (global.set $cursor (local.get 0))
  )

  ;; CURSOR GETTERS
  (func $cursor.get (export "cursor.get") (result i32)
    global.get $cursor
  )

  (func $cursor.next (export "cursor.next") (result i32)
    (i32.add (global.get $cursor) (i32.const 1))
  )

  (func $cursor.char (export "cursor.char") (result i32)
    (i32.load8_u (global.get $cursor))
  )

  (func $cursor.nextChar (export "cursor.nextChar") (result i32)
    (i32.load8_u (call $cursor.next))
  )

  ;; SAVE AND RESTAURE
  (func $cursor.save (export "cursor.save")
    (global.set $saved (global.get $cursor))
  )

  (func $cursor.restaure (export "cursor.restaure")
    (i32.gt_s (global.get $saved) (i32.const 0))
    (if
      (then
        (global.set $cursor (global.get $saved))
      )
    )
  )

  (func $cursor.hasMoved (export "cursor.hasMoved") (result i32)
    (i32.ne (global.get $cursor) (global.get $saved))
  )

  (func $cursor.char.save (export "cursor.char.save")
    (global.set $savedChar (call $cursor.char))
  )

  (func $cursor.isSavedChar (export "cursor.isSavedChar") (result i32)
    (i32.eq (global.get $savedChar) (call $cursor.char))
  )

  ;; SELECT SUBSTRING
  (table $callable 1 funcref)
  
  (func $select.while (export "select.while") (param $testFn funcref)
    (global.set $selection.start (global.get $cursor))

    (table.set $callable (i32.const 0) (local.get $testFn))
    (call_indirect $callable (type $int) (i32.const 0))

    (if
      (then
        (block $block
          (loop $loop
            call $cursor.inz
            call $isEnd
            br_if $block
            (table.set $callable (i32.const 0) (local.get $testFn))
            (call_indirect $callable (type $int) (i32.const 0))
            br_if $loop
          )
        )
      )
    )

    (global.set $selection.end (global.get $cursor))
    call $cursor.dnz
  )

  (func $select.until (export "select.until") (param $testFn funcref)
    (global.set $selection.start (global.get $cursor))

    (table.set $callable (i32.const 0) (local.get $testFn))
    (call_indirect $callable (type $int) (i32.const 0))
    i32.eqz

    (if
      (then
        (block $block
          (loop $loop
            call $cursor.inz
            call $isEnd
            br_if $block
            (table.set $callable (i32.const 0) (local.get $testFn))
            (call_indirect $callable (type $int) (i32.const 0))
            i32.eqz
            br_if $loop
          )
        )
      )
    )

    (global.set $selection.end (global.get $cursor))
    call $cursor.dnz
  )

  (func $select.fromSaved (export "select.fromSaved")
    (global.set $selection.start (global.get $saved))
    (global.set $selection.end (global.get $cursor))
  )

  (func $select.from (export "select.from") (param i32)
    (global.set $selection.start (local.get 0))
    (global.set $selection.end (global.get $cursor))
  )

  (func $selection.length (export "selection.length") (result i32)
    (i32.sub (global.get $selection.end) (global.get $selection.start))
  )

  (func $selection.get (export "selection.get") (result externref)
    (call $js.slice (global.get $selection.start) (global.get $selection.end))
  )

  (func $selection.clear (export "selection.clear")
    (global.set $selection.start (i32.const 0))
    (global.set $selection.end (i32.const 0))
  )

  ;; SKIPS
  (func $skip.while (export "skip.while") (param $testFn funcref)
    (table.set $callable (i32.const 0) (local.get $testFn))
    (call_indirect $callable (type $int) (i32.const 0))

    (if
      (then
        (block $block
          (loop $loop
            call $cursor.inz
            call $isEnd
            br_if $block
            (table.set $callable (i32.const 0) (local.get $testFn))
            (call_indirect $callable (type $int) (i32.const 0))
            br_if $loop
          )
        )
      )
    )
  )

  (func $skip.until (export "skip.until") (param $testFn funcref)
    (table.set $callable (i32.const 0) (local.get $testFn))
    (call_indirect $callable (type $int) (i32.const 0))
    i32.eqz

    (if
      (then
        (block $block
          (loop $loop
            call $cursor.inz
            call $isEnd
            br_if $block
            (table.set $callable (i32.const 0) (local.get $testFn))
            (call_indirect $callable (type $int) (i32.const 0))
            i32.eqz
            br_if $loop
          )
        )
      )
    )
  )

  ;; INCREMENT/DECREMENT FUNCTIONS
  (func $cursor.inz (export "cursor.inz")
    call $isEnd
    (if (then return))
    (i32.add (global.get $cursor) (i32.const 1))
    global.set $cursor
  )

  (func $cursor.dnz (export "cursor.dnz")
    (i32.eqz (global.get $cursor))
    (if (then return))
    (i32.sub (global.get $cursor) (i32.const 1))
    global.set $cursor
  )

  ;; LOG FUNCTIONS
  (func $cursor.log (export "cursor.log")
    global.get $cursor
    call $cursor.char
    call $js.logCursor
  )

  ;; IS STRING END
  (func $isEnd (export "isEnd") (result i32)
    (i32.eqz (call $cursor.char))
  )

)