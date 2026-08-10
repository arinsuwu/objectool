include

;   Co-processor checks
if read1($00FFD5) == $23
    if read1($00FFD7) == $0D
        fullsa1rom
        !fullsa1 = 1
    else
        sa1rom
        !fullsa1 = 0
    endif
    !sa1    = 1

    !dp    #= $3000
    !addr  #= $6000
    !ram   #= $400000
    !ram8  #= $40
    !bank  #= $000000
    !bank8 #= $00
else
    lorom
    !sa1 = 0
    !fullsa1 = 0

    !dp    #= $0000
    !addr  #= $0000
    !ram   #= $7E0000
    !ram8  #= $7E
    !bank  #= $800000
    !bank8 #= $80
endif

    optimize dp always
    dpbase !dp
    optimize address mirrors
    bank auto

;---

;   Extended defines
!SA1    = !sa1
!SA_1   = !sa1

!Base1 #= !dp
!Base2 #= !addr
!BankA #= !ram
!Map16 #= !ram8
!BankB #= !bank
!Bank8 #= !bank8

;---

;   Lunar Magic checks
    !EXLEVEL    = 0
if (((read1($0FF0B4)-'0')*100)+((read1($0FF0B4+2)-'0')*10)+(read1($0FF0B4+3)-'0')) > 253
    !EXLEVEL    = 1
endif

;-

;   Retry Multiple Midway Points check
;   TODO: better Retry check, specific to its MMPs
;   Kaijyuu's MMPs are compatible as is
    !retry_mmp  = 0
if read1($0DA104) == $5C && read2(read3($0DA104+1)-3) == $1337
    !retry_mmp  = 1
endif

;---

;   Tool versioning
; !objectool_version #= $0100
; !objectool_check    = equal(read4(read3($0DA107)-$16),$656A624F)&equal(read4(read3($0DA107)-$16+4),$6F6F7463)&equal(read1(read3($0DA107)-$16+8),$6C)
; if !objectool_check
;     !objectool_version_ROM      = ((read1(read3($0DA107)-$16+12)&$F)<<12)|((read1(read3($0DA107)-$16+13)&$F)<<8)|((read1(read3($0DA107)-$16+14)&$F)<<4)|(read1(read3($0DA107)-$16+14)&$F)
; else
;     !objectool_check = equal(read4(read3($0DA107)),$59A530E2)&equal(read2(read3($0DA107)+4),$98C9)
;     if !objectool_check
;         !objectool_version_ROM  = $0050
;     else
;         !objectool_version_ROM  = 0
;     endif
; endif

;---

;   Helper defines for custom objects
!obj_pos       #= $57
!extra_byte    #= $58
!extended_num  #= $59
!obj_settings  #= $59
!obj_num       #= $5A
!map16_low      = [$6B]
!map16_high     = [$6E]
!obj_screen    #= $1928|!addr
!tileset       #= $1931|!addr
!tile_screen   #= $1BA1|!addr

!extended_start = $98

;   80+ bytes used for scratch RAM in some routines to build tables
;   The address doesn't particularly matter, as long as anything else that would need it
;   reloads it before using it but after object code runs
!obj_scratch   #= $0910|!addr
!ObjScratch    #= !obj_scratch

