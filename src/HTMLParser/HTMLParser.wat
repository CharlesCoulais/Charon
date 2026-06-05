(module
  ;; IMPORTS
  (import "js" "registerTextNode" (func $js.registerTextNode (type $ext|ext)))
  (import "js" "createElement" (func $js.createElement (type $ext=>ext)))
  (import "js" "registerElement" (func $js.registerElement (type $ext|ext)))
  (import "js" "isSelfClosingEl" (func $js.isSelfClosingEl (type $ext=>i32)))
  (import "js" "registerAttribute"  (func $js.registerAttribute (type $ext|ext|ext)))
  (import "js" "registerClosingTag" (func $js.registerClosingTag (type $ext|ext)))
  (import "js" "isClosingTagOf" (func $js.isClosingTagOf (type $ext|ext=>i32)))
  (import "js" "isOrphanClosingTag" (func $js.isOrphanClosingTag (type $ext|ext=>i32)))
  (import "js" "createMissingClosingTag" (func $js.createMissingClosingTag (type $ext|ext)))
  (import "js" "ignoreOrphanClosingTag" (func $js.ignoreOrphanClosingTag (type $ext)))

  ;; (import "logger" "logBool" (func $logBool (type $i32)))
  ;; (import "logger" "logI32" (func $logI32 (type $i32)))
  ;; (import "logger" "logChar" (func $logChar (type $i32)))
  ;; (import "logger" "logStart" (func $logStart (type $i32)))
  ;; (import "logger" "logEnd" (func $logEnd (type $i32)))
  ;; (import "logger" "logRef" (func $logRef (type $ext)))

  (import "logicOperators" "and" (func $AND (type $int|int=>int)))
  (import "logicOperators" "not" (func $NOT (type $int=>int)))

  (import "htmlCursor" "cursor.log" (func $html.cursor.log))
  (import "htmlCursor" "cursor.get" (func $html.cursor.get (type $=>int)))
  (import "htmlCursor" "cursor.set" (func $html.cursor.set (type $i32)))
  (import "htmlCursor" "cursor.inz" (func $html.cursor.inz))
  (import "htmlCursor" "cursor.char" (func $html.cursor.char (type $=>int)))
  (import "htmlCursor" "cursor.next" (func $html.cursor.next (type $=>int)))
  (import "htmlCursor" "cursor.nextChar" (func $html.cursor.nextChar (type $=>int)))
  (import "htmlCursor" "isEnd" (func $html.isEnd (type $=>int)))
  (import "htmlCursor" "cursor.save" (func $html.cursor.save))
  (import "htmlCursor" "cursor.restaure" (func $html.cursor.restaure))
  (import "htmlCursor" "cursor.hasMoved" (func $html.cursor.hasMoved (type $=>int)))
  (import "htmlCursor" "cursor.char.save" (func $html.cursor.char.save))
  (elem declare func $html.cursor.isSavedChar)
  (import "htmlCursor" "cursor.isSavedChar" (func $html.cursor.isSavedChar (type $=>int)))
  (import "htmlCursor" "select.while" (func $html.select.while (type $fn)))
  (import "htmlCursor" "select.until" (func $html.select.until (type $fn)))
  (import "htmlCursor" "select.fromSaved" (func $html.select.fromSaved))
  (import "htmlCursor" "select.from" (func $html.select.from (type $i32)))
  (import "htmlCursor" "selection.length" (func $html.selection.length (type $=>int)))
  (import "htmlCursor" "selection.get" (func $html.selection.get (type $=>ext)))
  (import "htmlCursor" "selection.clear" (func $html.selection.clear))
  (import "htmlCursor" "skip.while" (func $html.skip.while (type $fn)))
  (import "htmlCursor" "skip.until" (func $html.skip.until (type $fn)))
  
  (elem declare func $spaceCharset.includes)
  (import "spaceCharset" "includes" (func $spaceCharset.includes (type $int=>int)))
  (elem declare func $tagnameCharset.includes)
  (import "tagnameCharset" "includes" (func $tagnameCharset.includes (type $int=>int)))
  (elem declare func $quoteCharset.includes)
  (import "quoteCharset" "includes" (func $quoteCharset.includes (type $int=>int)))


  ;; TYPES
  (type $=>int (func (result i32)))
  (type $i32 (func (param i32)))
  (type $int=>int (func (param i32) (result i32)))
  (type $int|int=>int (func (param i32) (param i32) (result i32)))

  (type $fn (func (param funcref)))
  
  (type $=>ext (func (result externref)))
  (type $ext (func (param externref)))
  (type $ext=>ext(func (param externref) (result externref)))
  (type $ext|ext (func (param externref) (param externref)))
  (type $ext|ext|ext (func (param externref) (param externref) (param externref)))
  (type $ext|ext=>i32(func (param externref) (param externref) (result i32)))
  (type $ext=>i32 (func (param externref) (result i32)))


  ;; SPECIAL CHARS
  (global $ltChar (mut i32) (i32.const 60)) ;; <
  (global $eqChar (mut i32) (i32.const 61)) ;; =
  (global $gtChar (mut i32) (i32.const 62)) ;; >
  (global $slashChar (mut i32) (i32.const 47)) ;; /

  ;; PARSE
  (func (export "parseHTML") (param $rootEl externref) (result externref)
    (call $parseContent (local.get $rootEl))
    local.get $rootEl
  )

  (func $parseContent (param $parentEl externref)
    (local $subI i32)
    ;;(local $limit i32) (local.set $limit (i32.const 1))

    (loop $loop
      (block $block
        call $html.cursor.isOpenTag
        (if (then
          (call $parseElement (local.get $parentEl))
          br $block
        ))

        call $html.cursor.isClosingTag
        (if (then br $block))

        (call $parseTextNode (local.get $parentEl))
      )

      (call $ignoreOrphanClosingTags (local.get $parentEl))

      (call $AND
        (call $NOT (call $html.cursor.isClosingTag))
        (call $NOT (call $html.isEnd))
      )
      ;;(call $AND (i32.gt_u (local.tee $limit (i32.sub (local.get $limit) (i32.const 1))) (i32.const 0)))
      br_if $loop
    )
  )

  ;; TAG TESTS
  (elem declare func $html.cursor.isOpenTag)
  (func $html.cursor.isOpenTag (result i32)
    call $html.cursor.isTagOpenChar
    (if (then
      (return (call $html.cursor.isTagNameChar))
    ))
    (return (i32.const 0))
  )

  (elem declare func $html.cursor.isClosingTag)
  (func $html.cursor.isClosingTag (result i32)
    call $html.cursor.isTagOpenChar
    (if (then
      (return (call $html.cursor.next.isSlashChar))
    ))
    (return (i32.const 0))
  )

  (elem declare func $html.cursor.isTag)
  (func $html.cursor.isTag (result i32)
    call $html.cursor.isOpenTag
    (if (then
      (return (i32.const 1))
    ))
    call $html.cursor.isClosingTag
  )


  ;; TEXT NODES
  (func $parseTextNode (param $parentEl externref)
    (call $html.select.until (ref.func $html.cursor.isTag))
    (i32.ne (call $html.selection.length) (i32.const 0))
    (if (then
      call $html.selection.get
      (call $js.registerTextNode (local.get $parentEl))
      call $html.cursor.inz
    ))
  )

  ;; TAGS
  (func $getTagName (result externref)
    ;; skip "<"
    call $html.cursor.inz
    (call $html.skip.while (ref.func $html.cursor.isSpaceChar))
    (call $html.select.while (ref.func $html.cursor.isTagnameChar))
    call $html.selection.get
    call $html.cursor.inz
  )

  (func $getEndTagName (result externref)
    ;; skip "</"
    (call $html.cursor.set (i32.add (call $html.cursor.get) (i32.const 2)))
    (call $html.skip.while (ref.func $html.cursor.isSpaceChar))
    (call $html.select.while (ref.func $html.cursor.isTagnameChar))
    call $html.selection.get
    call $html.cursor.inz
  )

  (func $registerClosingTag (param $currentEl externref)
    (local $tagName externref)

    call $html.cursor.save
    (local.set $tagName (call $getEndTagName))
    (call $js.isClosingTagOf (local.get $tagName) (local.get $currentEl))
    (if
      (then
        (call $js.registerClosingTag (local.get $tagName) (local.get $currentEl))
        (call $html.skip.until (ref.func $html.cursor.isTagClosingChar))
        call $html.cursor.inz
      )
      (else
        (call $js.createMissingClosingTag (local.get $tagName) (local.get $currentEl))
        call $html.cursor.restaure
      )
    )
    call $html.cursor.save
  )

  (func $ignoreOrphanClosingTags (param $el externref)
    (local $tagName externref)

    (loop $loop
      call $html.cursor.save

      call $html.cursor.isClosingTag
      (if
        (then
          (local.tee $tagName (call $getEndTagName))
          local.get $el

          call $js.isOrphanClosingTag
          (if
            (then
              ;; js hook
              (call $js.ignoreOrphanClosingTag (local.get $tagName))
              ;; skip until tag end char
              (call $html.skip.while (ref.func $html.cursor.isTagClosingChar))
            )
            (else
              call $html.cursor.restaure
            )
          )
        )
      )

      (call $AND
        (call $html.cursor.hasMoved)
        (i32.eqz (call $html.isEnd))
      )
      br_if $loop
    )
  )

  ;; ELEMENT NODES
  (func $parseElement (param $parentEl externref)
    (local $el externref)
    (local $savedPosition i32)
    
    (local.set $savedPosition (call $html.cursor.get))
    

    ;; create element
    call $getTagName
    call $js.createElement
    local.set $el

    ;; extract attributes
    (call $parseAttributes (local.get $el))

    (call $NOT (call $html.cursor.isTagClosingChar))
    (if
      (then
        (call $html.select.from (local.get $savedPosition))
        (i32.ne (call $html.selection.length) (i32.const 0))
        (if (then
          call $html.selection.get
          (call $js.registerTextNode (local.get $parentEl))
          call $html.cursor.inz
        ))
        return
      )
      (else
        call $html.cursor.inz
      )
    )
    (call $js.registerElement (local.get $el) (local.get $parentEl))

    (call $js.isSelfClosingEl (local.get $el))
    (if (then return))

    (call $parseContent (local.get $el))

    call $html.cursor.isClosingTag
    (if (then
      (call $registerClosingTag (local.get $el))
    ))
  )

  ;; ATTRIBUTES
  (func $parseAttributes (param $el externref)
    (loop $loop
      (call $html.skip.while (ref.func $html.cursor.isSlashOrSpaceChar))
  
      call $html.cursor.isAttrNameChar
      (if
        (then
          (call $js.registerAttribute
            (call $getAttrName)
            (call $getAttrValue)
            (local.get $el)
          )
        )
      )

      (call $NOT (call $html.cursor.isTagEnd))
      br_if $loop
    )
  )

  (func $getAttrName (result externref)
    call $html.cursor.save
    (loop $loop
      call $html.cursor.inz
      (call $AND
        (call $html.cursor.isAttrNameChar)
        (call $NOT (call $html.cursor.isEqChar))
      )
      br_if $loop
    )
    call $html.select.fromSaved
    call $html.selection.get
  )

  (func $getAttrValue (result externref)
    (call $html.skip.while (ref.func $html.cursor.isSpaceChar))

    (call $NOT (call $html.cursor.isEqChar))
    (if
      (then
        call $html.selection.clear
        call $html.selection.get
        return
      )
    )

    call $html.cursor.inz
    (call $html.skip.while (ref.func $html.cursor.isSpaceChar))

    call $html.cursor.isTagEnd
    (if
      (then
        call $html.selection.clear
        call $html.selection.get
        return
      )
    )

    (call $html.cursor.isQuoteChar)
    (if
      (then
        call $html.cursor.char.save
        call $html.cursor.inz
        (call $html.select.until (ref.func $html.cursor.isSavedChar))
        call $html.cursor.inz
        call $html.cursor.inz
      )
      (else
        (call $html.select.until (ref.func $html.cursor.isSpaceChar))
        call $html.cursor.inz
      )
    )
    call $html.selection.get
  )

  ;; CHAR TESTS
  (func $html.cursor.isTagOpenChar (result i32)
    (i32.eq
      (call $html.cursor.char)
      (global.get $ltChar)
    )
  )

  (elem declare func $html.cursor.isTagClosingChar)
  (func $html.cursor.isTagClosingChar (result i32)
    (i32.eq
      (call $html.cursor.char)
      (global.get $gtChar)
    )
  )

  (elem declare func $html.cursor.isTagEnd)
  (func $html.cursor.isTagEnd (result i32)
    call $html.cursor.isTagClosingChar
    (if (then (return (i32.const 1))))
    call $html.isEnd
  )

  (elem declare func $html.cursor.isTagNameChar)
  (func $html.cursor.isTagNameChar (result i32)
    (call $tagnameCharset.includes (call $html.cursor.nextChar))
  )

  (elem declare func $html.cursor.next.isSlashChar)
  (func $html.cursor.next.isSlashChar (result i32)
    (i32.eq
      (call $html.cursor.nextChar)
      (global.get $slashChar)
    )
  )

  (elem declare func $html.cursor.isSlashChar)
  (func $html.cursor.isSlashChar (result i32)
    (i32.eq
      (call $html.cursor.char)
      (global.get $slashChar)
    )
  )

  (elem declare func $html.cursor.isEqChar)
  (func $html.cursor.isEqChar (result i32)
    (i32.eq
      (call $html.cursor.char)
      (global.get $eqChar)
    )
  )

  (elem declare func $html.cursor.isSpaceChar)
  (func $html.cursor.isSpaceChar (result i32)
    (call $spaceCharset.includes (call $html.cursor.char))
  )

  (elem declare func $html.cursor.isTagnameChar)
  (func $html.cursor.isTagnameChar (result i32)
    (call $tagnameCharset.includes (call $html.cursor.char))
  )

  (elem declare func $html.cursor.isQuoteChar)
  (func $html.cursor.isQuoteChar (result i32)
    (call $quoteCharset.includes (call $html.cursor.char))
  )

  (elem declare func $html.cursor.isSlashOrSpaceChar)
  (func $html.cursor.isSlashOrSpaceChar (result i32)
    call $html.cursor.isSpaceChar
    (if (then (return (i32.const 1))))
    (return (call $html.cursor.isSlashChar))
  )

  (elem declare func $html.cursor.isAttrNameChar)
  (func $html.cursor.isAttrNameChar (result i32)
    (call $NOT (call $html.cursor.isSlashOrSpaceChar))
    (if (then
      (return (call $NOT (call $html.cursor.isTagEnd))))
    )
    i32.const 0
  )

)

