;==========================================================
; ObjecTool - v2.0.0
;
; This wouldn't be possible without the following people:
;  Original ObjecTool patch - 0x400, imamelia
;    Modern ObjecTool patch - Arinsu, Burning Loaf
;  Original ObjecTool tool  - Burning Loaf
;    Modern ObjecTool tool  - Arinsu
;==========================================================

padbyte $00

extended_object_ptrs    = $0DA10F|!bank
done_objects            = $0586D6|!bank

;---

org $0DA100
    ;   Tool signature in the ROM
objectool_header:
    db "OT", $02, $00

    ;   Four bytes reserved for a Retry system springboard
retry_mmp_handler:
    if read1($0DA104) != $5C
        RTL : NOP #3
    else
        skip 4
    endif
    

    pad $0DA10F

;-

    ;   Object load hijacks
org $0586C5
    LDA $5A
    BNE standard_object
extended_object:
    REP #$30
    autoclean JML load_extended_object
standard_object:
    SEP #$30
    autoclean JML load_standard_object

;---

freecode

    ;   AXY 16-bit on entry
    ;   This handler now takes care of both vanilla and custom objects.
load_extended_object:
    PHB

    LDA !extended_num
    ASL
    ADC !extended_num
    TAX
    ;   $00-$02 -> Extended object pointers
    LDA.l extended_object_ptrs,x
    STA $00
    LDA.l extended_object_ptrs+2,x
    SEP #$30
    STA $02
    PHA
    PLB

    PHK
    PEA.w custom_object_return-1
    ;   X -> Extended object number (expected by vanilla extended objects)
    LDX !extended_num
    CPX #$98
    BCS .run_extended_object
    ;   RTL in bank 0D to redirect the vanilla objects
    PEA $A413
    ;   Expected for the old patch's extended ojects
    SEC
.run_extended_object
    JML [$0000|!dp]

;---

    ;   AXY 8-bit on entry
load_standard_object:
    ;   If not standard object 2D, run the vanilla object code
    CMP #$2D
    BEQ .custom_standard_object
.vanilla_standard_object
    ;   Jumping here and not to $0DA411 just in case something else hacks there
    JSL $0DA40F|!bank
.done_standard_object
    SEP #$20
    REP #$10
    JML done_objects

.custom_standard_object
    PHB

    REP #$30
    ;   Extra byte
    LDA [$65]
    XBA
    STA !extra_byte
    ;   Custom object number
    XBA
    AND #$00FF
    STA !obj_num
    ASL
    ADC !obj_num
    TAX

    ;   Offset for 2 extra bytes in standard object 2D
    ;   (ts NOT in a bank border bro :sob::v:)
    LDA $65
    INC #2
    STA $65

    ;   $00-$02 -> Standard object pointers
    LDA.l standard_object_ptrs,x
    STA $00
    LDA.l standard_object_ptrs+2,x
    SEP #$30
    STA $02

    ;   In case you're using Retry, this is intended as a jump to run its multiple midway point code
    if !retry_mmp
        LDX !obj_num
        CPX #$42
        BCC ..is_retry_mmp
        CPX #$50
        BEQ ..is_retry_mmp
        CPX #$51
        BNE ..no_retry_mmp
    ..is_retry_mmp
        JSL retry_mmp_handler|!bank
        BRA custom_object_return

    ..no_retry_mmp
    endif

    PHA
    PLB

    PHK
    PEA.w custom_object_return-1
    ;   Expected for the old patch's standard ojects
    CLC
    JML [$0000|!dp]

;-

    ;   Used by both springboards above.
custom_object_return:
    PLB
    SEP #$20
    REP #$10
    JML done_objects

;---
