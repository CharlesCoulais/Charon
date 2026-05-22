(module
  (import "export" "log" (func $log (param i32) (param i32)))
  (import "export" "registerTextNode" (func $registerTextNode (param i32) (param i32) (param $parentEl externref)))
  (import "export" "createElement" (func $createElement (param i32) (param i32) (result externref)))
  (import "export" "registerElement" (func $registerElement (param $el externref) (param $parentEl externref)))
  (import "export" "isSelfClosingEl" (func $isSelfClosingEl (param $el externref) (result i32)))
  (import "export" "registerElementAttribute"  (func $registerElementAttribute (param i32) (param i32) (param i32) (param i32) (param $el externref)))
  (import "export" "logEndTag" (func $logEndTag (param i32) (param i32) (param $el externref)))
  (import "export" "isEndTagOf" (func $isEndTagOf (param i32) (param i32) (param $el externref) (result i32)))
  (import "export" "isOrphanEndTag" (func $isOrphanEndTag (param i32) (param i32) (param $el externref) (result i32)))
  (import "js" "mem" (memory 1))
  

  ;;LOG FUNCTIONS
  (func $logBool (param i32)
    i32.const 1
    local.get 0
    call $log
  )
  (func $logI32 (param i32)
    i32.const 2
    local.get 0
    call $log
  )
  (func $logChar (type $eachFnType)
    i32.const 3
    local.get 0
    call $log
  )
  (func $logCharAt (type $eachFnType)
    i32.const 3
    (call $getValueAt (local.get 0))
    call $log
  )


  ;;MEMORY VALUES GETTERS
  (func $i32ToI8Index (param i32) (result i32)
    (i32.mul (local.get 0) (i32.const 4))
  )

  (func $getValueHeaderI32Index (param $valueIndex i32) (result i32)
    local.get $valueIndex
    i32.const 3
    i32.mul
    i32.const 2
    i32.add
  )

  (func $getValueType (param $valueIndex i32) (result i32)
    (call $getValueHeaderI32Index (local.get $valueIndex))
    call $i32ToI8Index
    i32.load
  )

  (func $getValueOffset (param $valueIndex i32) (result i32)
    local.get $valueIndex
    call $getValueHeaderI32Index
    i32.const 1
    i32.add
    call $i32ToI8Index
    i32.load
    call $i32ToI8Index
  )
  
  (func $getValueLength (param $valueIndex i32) (result i32)
    local.get $valueIndex
    call $getValueHeaderI32Index
    i32.const 2
    i32.add
    call $i32ToI8Index
    i32.load
  )

  (func $getValueEnd (param $valueIndex i32) (result i32)
    (call $getValueOffset (local.get $valueIndex))
    (call $getValueLength (local.get $valueIndex))
    i32.add
  )

  (func $getValueAt (param i32) (result i32)
    (i32.load8_u (local.get 0))
  )

  (func $isValueEnd (param $i i32) (result i32)
    (i32.eqz (call $getValueAt (local.get $i)))
  )


  ;;INCREMENT/DECREMENT FUNCTIONS
  (func $inz (param i32) (result i32)
    local.get 0
    i32.const 1
    i32.add
  )

  (func $dnz (param i32) (result i32)
    local.get 0
    i32.const 1
    i32.sub
  )

  ;;FOREACH LOOP
  (table $eachTable 1 funcref)
  (type $eachFnType (func (param $i i32)))

  (func $foreach (param $i i32) (param $end i32) (param $fn funcref)
    (i32.lt_s (local.get $i) (local.get $end))
    (if
      (then
        (loop $loop
          (table.set $eachTable (i32.const 0) (local.get $fn))
          (call_indirect $eachTable (type $eachFnType) (local.get $i) (i32.const 0))
        
          (local.set $i (call $inz (local.get $i)))

          (i32.lt_u (local.get $i) (local.get $end))
          br_if $loop
        )
      )
    )
  )


  ;;MEMORY COMPARE FUNCTIONS
  (elem declare func $eqMemoryValue)
  (func $eqMemoryValue (type $p32p32r32) (param $i i32) (param $searchValue i32) (result i32)
    (call $getValueAt (local.get $i))
    local.get $searchValue
    i32.eq
  )
  (elem declare func $neMemoryValue)
  (func $neMemoryValue (type $p32p32r32) (param $i i32) (param $searchValue i32) (result i32)
    (call $getValueAt (local.get $i))
    local.get $searchValue
    i32.ne
  )


  ;;UNTIL LOOPS
  (table $untilTable 1 funcref)
  (type $p32p32r32 (func (param i32) (param i32) (result i32)))
  (type $p32r32 (func (param $i i32) (result i32)))
  
  (func $loopUntil (param $i i32) (param $value i32) (param $testFn funcref) (result i32)
    (table.set $untilTable (i32.const 0) (local.get $testFn))

    (i32.const 1)
    (call_indirect $untilTable (type $p32p32r32) (local.get $i) (local.get $value) (i32.const 0))
    i32.sub

    (if
      (then
        (block $block
          (loop $loop
            (local.set $i (call $inz (local.get $i)))

            (call $isValueEnd (local.get $i))
            br_if $block

            (table.set $untilTable (i32.const 0) (local.get $testFn))
            (i32.const 1)
            (call_indirect $untilTable (type $p32p32r32) (local.get $i) (local.get $value) (i32.const 0))
            i32.sub

            br_if $loop
          )
        )
      )
    )

    (local.get $i)
  )

  (func $loopUntilEq (param $i i32) (param $value i32) (result i32)
    (call $loopUntil (local.get $i) (local.get $value) (ref.func $eqMemoryValue))
  )

  (func $loopUntilNe (param $i i32) (param $value i32) (result i32)
    (call $loopUntil (local.get $i) (local.get $value) (ref.func $neMemoryValue))
  )

  (func $loopUntilTest (param $i i32) (param $testFn funcref) (result i32)
    (table.set $untilTable (i32.const 0) (local.get $testFn))

    (i32.const 1)
    (call_indirect $untilTable (type $p32r32) (local.get $i) (i32.const 0))
    i32.sub

    (if
      (then
        (block $block
          (loop $loop
            (local.set $i (call $inz (local.get $i)))

            (call $isValueEnd (local.get $i))
            br_if $block


            (table.set $untilTable (i32.const 0) (local.get $testFn))
            (i32.const 1)
            (call_indirect $untilTable (type $p32r32) (local.get $i) (i32.const 0))
            i32.sub

            br_if $loop
          )
        )
      )
    )

    (local.get $i)
  )


  ;;WHILE LOOPS
  (table $whileTable 1 funcref)
  
  (func $loopWhile (param $i i32) (param $value i32) (param $testFn funcref) (result i32)
    (table.set $whileTable (i32.const 0) (local.get $testFn))
    (call_indirect $whileTable (type $p32p32r32) (local.get $i) (local.get $value) (i32.const 0))

    (if
      (then
        (block $block
          (loop $loop
            (local.set $i (call $inz (local.get $i)))

            (call $isValueEnd (local.get $i))
            br_if $block

            (table.set $whileTable (i32.const 0) (local.get $testFn))
            (call_indirect $whileTable (type $p32p32r32) (local.get $i) (local.get $value) (i32.const 0))

            br_if $loop
          )
        )
      )
    )

    (local.get $i)
  )

  (func $loopWhileEq (param $i i32) (param $value i32) (result i32)
    (call $loopWhile (local.get $i) (local.get $value) (ref.func $eqMemoryValue))
  )

  (func $loopWhileNe (param $i i32) (param $value i32) (result i32)
    (call $loopWhile (local.get $i) (local.get $value) (ref.func $neMemoryValue))
  )
  
  (func $loopWhileTest (param $i i32) (param $testFn funcref) (result i32)
    (table.set $whileTable (i32.const 0) (local.get $testFn))
    (call_indirect $whileTable (type $p32r32) (local.get $i) (i32.const 0))

    (if
      (then
        (block $block
          (loop $loop
            (local.set $i (call $inz (local.get $i)))

            (call $isValueEnd (local.get $i))
            br_if $block

            (table.set $whileTable (i32.const 0) (local.get $testFn))
            (call_indirect $whileTable (type $p32r32) (local.get $i) (i32.const 0))

            br_if $loop
          )
        )
      )
    )

    (local.get $i)
  )

  ;;FIND INDEX
  (func $indexOf (param $i i32) (param $value i32) (result i32)
    (call $loopUntilEq (local.get $i) (local.get $value))
    local.set $i

    (select
      (i32.const -1)
      (local.get $i)
      (call $isValueEnd (local.get $i))
    )
  )


  ;;GLOBALS
  (global $dataLen (mut i32) (i32.const 0))
  (global $argsCount (mut i32) (i32.const 0))

  (global $ltChar (mut i32) (i32.const 0))
  (global $gtChar (mut i32) (i32.const 0))
  (global $slashChar (mut i32) (i32.const 2))
  (global $tagCharsIndex (mut i32) (i32.const 3)) ;;tag chars list
  (global $spaceCharsIndex (mut i32) (i32.const 4)) ;;space chars list
  (global $eqChar (mut i32) (i32.const 5))
  (global $quoteCharIndex (mut i32) (i32.const 6))
  (global $htmlStrIndex (mut i32) (i32.const 7))

  ;;INIT
  (func $init
    (global.set $dataLen (i32.load (i32.const 0)))
    (global.set $argsCount (i32.load (i32.const 4)))

    (global.set $ltChar (call $getValueAt (call $getValueOffset (i32.const 0))))
    (global.set $gtChar (call $getValueAt (call $getValueOffset (i32.const 1))))
    (global.set $slashChar (call $getValueAt (call $getValueOffset (i32.const 2))))
    
    (global.set $eqChar (call $getValueAt (call $getValueOffset (i32.const 5))))
  )


  ;;EXPORT
  (func (export "parseHTML") (param $rootEl externref) (result externref)
    (local $i i32)
    (local $end i32)
    ;;(local $limit i32) (local.set $limit (i32.const 10))

    (call $init)
    (local.set $i (call $getValueOffset (global.get $htmlStrIndex)))
    (local.set $end (call $getValueEnd (global.get $htmlStrIndex)))

    (loop $loop
      (call $parse (local.get $i) (local.get $rootEl))
      local.set $i

      (call $isCloseTag (local.get $i))
      (if 
        (then
          (call $registerCloseTag (local.get $i) (local.get $rootEl))
          local.set $i
        )
      )
      
      (call $logicNOT (call $isValueEnd (local.get $i)))
      ;;(call $logicAND (i32.gt_u (local.tee $limit (call $dnz (local.get $limit))) (i32.const 0)))
      br_if $loop
    )

    local.get $rootEl
  )

  (func $parse (param $i i32) (param $parentEl externref) (result i32)
    (local $subI i32)
    ;;(local $limit i32)
    ;;(local.set $limit (i32.const 100))

    (loop $loop
      (call $extractTextNode (local.get $i) (local.get $parentEl))
      local.set $i

      (call $isOpenTag (local.get $i))
      (if
        (then
          (call $extractElement (local.get $i) (local.get $parentEl))
          local.set $i
        )
      )

      (call $ignoreOrphanCloseTags (local.get $i) (local.get $parentEl))
      local.set $i

      (call $logicAND
        (call $logicNOT (call $isCloseTag (local.get $i)))
        (call $logicNOT (call $isValueEnd (local.get $i)))
      )
      ;;(call $logicAND (i32.gt_u (local.tee $limit (call $dnz (local.get $limit))) (i32.const 0)))
      br_if $loop
    )

    local.get $i
  )


  ;;LOGIC OPERATOR FUNCTIONS
  (func $logicOR (param $x i32) (param $y i32) (result i32)
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

  (func $logicAND (param $x i32) (param $y i32) (result i32)
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

  (func $logicNOT (param $value i32) (result i32)
    (select
      (i32.const 1)
      (i32.const 0)
      (i32.eqz (local.get $value))
    )    
  )

  ;;TAG DETECTION FUNCTIONS
  (elem declare func $isOpenTag)
  (func $isOpenTag (param $i i32) (result i32)
    (i32.eq
      (call $getValueAt (local.get $i))
      (global.get $ltChar)
    )
    (call $isTagChar
      (call $inz (local.get $i))
    )
    call $logicAND
  )

  (elem declare func $isCloseTag)
  (func $isCloseTag (param $i i32) (result i32)
    (i32.eq
      (call $getValueAt (local.get $i))
      (global.get $ltChar)
    )
    (i32.eq
      (call $getValueAt (call $inz (local.get $i)))
      (global.get $slashChar)
    )
    call $logicAND
  )

  (elem declare func $isTag)
  (func $isTag (param $i i32) (result i32)
    (call $logicOR
      (call $isOpenTag (local.get $i))
      (call $isCloseTag (local.get $i))
    )
  )

  (func $hasEndTagChar (param $i i32) (result i32)
    (i32.gt_s
      (call $indexOf (local.get $i) (global.get $gtChar))
      (i32.const -1)
    )
  )

  (func $getEndTagName (param $i i32) (result i32) (result i32)
    (local $end i32)

    (local.set $i (i32.add (local.get $i) (i32.const 2)))
    (call $skipSpaces (local.get $i))
    local.tee $i
    call $loopOverTagName
    (local.set $end (call $dnz))

    local.get $i
    local.get $end
  )


  ;;NODES EXTRACTION FUNCTIONS
  (func $extractTextNode (param $i i32) (param $parentEl externref) (result i32)
    (local $j i32)

    ;;early return
    (call $isTag (local.get $i))
    (if (then
      (return (local.get $i))
    ))

    ;;early return
    (call $isValueEnd (local.get $i))
    (if (then
      (return (local.get $i))
    ))

    (call $loopUntilTest (call $inz (local.get $i)) (ref.func $isTag))
    local.set $j

    (call $rawExtractTextNode (local.get $i) (local.get $j) (local.get $parentEl))

    local.get $j
  )

  (func $rawExtractTextNode (param $start i32) (param $end i32) (param $parentEl externref)
    (i32.ne (local.get $start) (local.get $end))
    (if (then
      (call $registerTextNode (local.get $start) (call $dnz (local.get $end)) (local.get $parentEl))
    ))
  )

  (func $registerCloseTag (param $i i32) (param $currentEl externref) (result i32)
    (local $start i32)
    (local $end i32)

    (call $getEndTagName (local.get $i))
    local.set $end
    local.set $start

    (call $isEndTagOf (local.get $start) (local.get $end) (local.get $currentEl))
    (if (then
      (call $logEndTag (local.get $start) (local.get $end) (local.get $currentEl))
      (call $loopUntilEq (local.get $end) (global.get $gtChar))
      (return (call $inz))
    ))

    local.get $i
  )

  (func $ignoreOrphanCloseTags (param $i i32) (param $el externref) (result i32)
    (local $j i32)
    (local.set $j (local.get $i))

    (loop $loop
      (local.set $i (local.get $j))

      (call $isCloseTag (local.get $j ))
      (if
        (then
          (call $isOrphanEndTag (call $getEndTagName (local.get $j)) (local.get $el))
          (if (then
            (call $ignoreCloseTag (local.get $j) (local.get $el))
            (local.set $j)
          ))
        )
      )

      (call $logicAND
        (i32.ne (local.get $i) (local.get $j))
        (call $logicNOT (call $isValueEnd (local.get $j)))
      )
      br_if $loop
    )

    (local.get $i)
  )

  (func $ignoreCloseTag (param $i i32) (param $currentEl externref) (result i32)
    (local $j i32)

    (local.set $i (i32.add (local.get $i) (i32.const 2)))
    (call $skipSpaces (local.get $i))
    local.tee $i
    call $loopOverTagName
    local.set $j
    (call $logEndTag (local.get $i) (call $dnz (local.get $j)) (local.get $currentEl))
    (call $loopUntilEq (local.get $i) (global.get $gtChar))

    call $inz
  )

  (func $extractElement (param $i i32) (param $parentEl externref) (result i32)
    (local $el externref)
    (local $start i32)
    (local $end i32)
    
    (local.set $start (call $inz (local.get $i)))
    (call $skipSpaces (local.get $start))
    local.set $start
    (call $loopOverTagName (local.get $start))
    local.set $end
    (call $createElement (local.get $start) (call $dnz (local.get $end)))
    local.set $el
    (call $extractAttributes (local.get $end) (local.get $el))
    local.set $end

    (call $logicNOT (call $isEndTagChar (local.get $end)))
    (if
      (then
        (call $rawExtractTextNode (local.get $i) (local.get $end) (local.get $parentEl))
        (return (local.get $end))
      )
    )
    (call $registerElement (local.get $el) (local.get $parentEl))
    (call $isSelfClosingEl (local.get $el))
    (if
      (then
        (call $logEndTag (i32.const -1) (i32.const -1) (local.get $el))
        (return (local.get $end))
      )
    )

    (call $parse (call $inz (local.get $end)) (local.get $el))
    local.set $end

    (call $isCloseTag (local.get $end))
    (if 
      (then
        (call $registerCloseTag (local.get $end) (local.get $el))
        return
      )
    )

    local.get $end
  )

  (func $extractAttributes (param $i i32) (param $el externref) (result i32)
    (local $nameStart i32)
    (local $nameEnd i32)
    (local $valueStart i32)
    (local $valueEnd i32)

    (loop $loop
      (call $skipNonAttrNameChars (local.get $i))
      local.set $i
    
      (call $logicNOT (call $isEndTagChar (local.get $i)))
      (call $logicNOT (call $isValueEnd (local.get $i)))
      call $logicAND
      (if
        (then
          (local.set $valueStart (i32.const -1))
          (local.set $valueEnd (i32.const -1))
          (local.tee $nameStart (local.get $i))
          (local.tee $nameEnd (call $extractAttrName))
          (local.tee $i (call $skipSpaces (call $inz)))

          call $isEqChar
          (if
            (then
              (local.set $i (call $skipSpaces (call $inz(local.get $i))))

              (call $logicNOT (call $isEndTagChar (local.get $i)))
              (call $logicNOT (call $isValueEnd (local.get $i)))
              call $logicAND
              (if
                (then
                  (call $extractAttrValue (local.get $i))
                  local.set $valueStart
                  local.tee $valueEnd
                  (local.set $i (i32.add (i32.const 2)))
                )
              )
            )
          )

          (call $registerElementAttribute
            (local.get $nameStart)
            (local.get $nameEnd)
            (local.get $valueStart)
            (local.get $valueEnd)
            (local.get $el)
          )
        )
      )

      (call $logicNOT (call $isEndTagChar (local.get $i)))
      (call $logicNOT (call $isValueEnd (local.get $i)))
      call $logicAND
      br_if $loop
    )

    local.get $i
  )

  (func $extractAttrName (param $i i32) (result i32)
    (loop $loop
      (local.set $i (call $inz (local.get $i)))

      (call $logicNOT (call $isSpaceChar (local.get $i)))
      (call $logicNOT (call $isEqChar (local.get $i)))
      call $logicAND
      (call $logicNOT (call $isEndTagChar (local.get $i)))
      call $logicAND
      (call $logicNOT (call $isValueEnd (local.get $i)))
      call $logicAND
      br_if $loop
    )

    (call $dnz (local.get $i))
  )

  (func $extractAttrValue (param $i i32) (result i32) (result i32)
    (local $endChar i32)
    (local $start i32)
    (local $end i32)

    (call $isQuoteChar (local.get $i))
    (if
      (then
        (local.set $endChar (call $getValueAt (local.get $i)))
        (local.set $start (call $inz (local.get $i)))
        (call $loopUntilEq (local.get $start) (local.get $endChar))
        (local.set $end (call $dnz))
      )
      (else
        (local.set $start (local.get $i))
        (call $loopUntilTest (local.get $i) (ref.func $isSpaceChar))
        (local.set $end (call $dnz))
      )
    )

    local.get $end
    local.get $start
  )

  (func $skipNonAttrNameChars (param $i i32) (result i32)
    (loop $loop
      (call $skipSpaces (local.get $i))
      local.set $i
      (call $loopWhileEq (local.get $i) (global.get $slashChar))
      local.set $i

      (call $isSpaceChar (local.get $i))
      (call $logicNOT (call $isValueEnd (local.get $i)))
      call $logicAND
      br_if $loop
    )

    local.get $i
  )

  (func $isEndTagChar (param $i i32) (result i32)
    (i32.eq
      (call $getValueAt (local.get $i))
      (global.get $gtChar)
    )
  )

  (func $isEqChar (param $i i32) (result i32)
    (i32.eq
      (call $getValueAt (local.get $i))
      (global.get $eqChar)
    )
  )

  (func $isQuoteChar (param $i i32) (result i32)
    (call $matchAny
      (call $getValueAt (local.get $i))
      (global.get $quoteCharIndex)
    )
  )

  (elem declare func $isSpaceChar)
  (func $isSpaceChar (param $i i32) (result i32)
    (call $matchAny
      (call $getValueAt (local.get $i))
      (global.get $spaceCharsIndex)
    )
  )

  (func $loopOverTagName (param $i i32) (result i32)
    (call $loopWhileTest (local.get $i) (ref.func $isTagChar))
  )

  (elem declare func $isTagChar)
  (func $isTagChar (param $i i32) (result i32)
    (call $matchAny
      (call $getValueAt (local.get $i))
      (global.get $tagCharsIndex)
    )
  )

  (func $skipSpaces (param $i i32) (result i32)
    (call $loopWhileTest (local.get $i) (ref.func $isSpaceChar))
  )

  (func $matchAny (param $char i32) (param $charListIndex i32) (result i32)
    (local $i i32)
    (local $end i32)

    (local.set $i (call $getValueOffset (local.get $charListIndex)))
    (local.set $end (call $getValueEnd (local.get $charListIndex)))
    
    (block $block
      (loop $loop
        (i32.ne (local.get $char) (call $getValueAt (local.get $i)))
        (local.set $i (call $inz (local.get $i)))
        (call $logicNOT (call $isValueEnd (local.get $i)))
        call $logicAND
        br_if $loop
      )
    )

    (call $logicNOT (call $isValueEnd (local.get $i)))
  )


  ;;VALUES COMPARE FUNCTIONS
  (func $stringCompare (param $str1Start i32) (param $str1End i32) (param $str2Start i32) (param $str2End i32) (result i32)
    (local $i i32)
    (local $result i32)
    (local $length i32)

    (call $strLen (local.get $str1Start) (local.get $str1End))
    (call $strLen (local.get $str2Start) (local.get $str2End))
    local.tee $length
    (local.tee $result (call $valueCompare))
    (if (then (return (local.get $result))))

    (local.set $i (i32.const 0))
    (loop $loop
      (call $valueCompare
        (call $getValueAt (i32.add (local.get $str1Start) (local.get $i)))
        (call $getValueAt (i32.add (local.get $str2Start) (local.get $i)))
      )
      local.tee $result
      i32.eqz

      (local.set $i (call $inz (local.get $i)))
      (i32.lt_u (local.get $i) (local.get $length))

      call $logicAND
      br_if $loop
    )

    local.get $result
  )

  (func $strLen (param $start i32) (param $end i32) (result i32)
    (i32.sub (local.get $end) (local.get $start))
  )

  (func $valueCompare (param $value1 i32) (param $value2 i32) (result i32)
    (i32.gt_u (local.get $value1) (local.get $value2))
    (if
      (then
        (return (i32.const 1))
      )
    )

    (i32.lt_u (local.get $value1) (local.get $value2))
    (if
      (then
        (return (i32.const -1))
      )
    )

    i32.const 0
  )

)

