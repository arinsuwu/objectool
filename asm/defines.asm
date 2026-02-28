
if read1($00FFD5) == $23		; check if the rom is sa-1
	if read1($00FFD7) == $0D	; full 6/8 mb sa-1 rom
		fullsa1rom
		!fullsa1 = 1
	else
		!fullsa1 = 0
		sa1rom
	endif
	!sa1 = 1
	!SA1 = 1
	!SA_1 = 1
	!Base1 = $3000
	!Base2 = $6000
	!dp = $3000
	!addr = $6000
	
	!BankA = $400000
	!BankB = $000000
	!bank = $000000
	
	!Bank8 = $00
	!bank8 = $00
	
	!map16 = $40
else
	lorom
	!sa1 = 0
	!SA1 = 0
	!SA_1 = 0
	!Base1 = $0000
	!Base2 = $0000
	!dp = $0000
	!addr = $0000

	!BankA = $7E0000
	!BankB = $800000
	!bank = $800000
	
	!Bank8 = $80
	!bank8 = $80
	
	!map16 = $7E
endif


!objectool_version = $0100
!objectool_check = equal(read4(read3($0DA107)-$16),$656A624F)&equal(read4(read3($0DA107)-$16+4),$6F6F7463)&equal(read1(read3($0DA107)-$16+8),$6C)
if !objectool_check
	!objectool_version_ROM = ((read1(read3($0DA107)-$16+12)&$F)<<12)|((read1(read3($0DA107)-$16+13)&$F)<<8)|((read1(read3($0DA107)-$16+14)&$F)<<4)|(read1(read3($0DA107)-$16+14)&$F)
else
	!objectool_check = equal(read4(read3($0DA107)),$59A530E2)&equal(read2(read3($0DA107)+4),$98C9)
	if !objectool_check
		!objectool_version_ROM = $0050
	else
		!objectool_version_ROM = 0
	endif
endif

; 80+ bytes used for scratch RAM in some routines to build tables
; the address doesn't particularly matter as long as anything else that would need it
; reloads it before using it but after object code runs
!ObjScratch = $0910|!addr
!obj_scratch = $0910|!addr

!obj_pos = $57
!extra_byte = $58
!extended_num = $59
!obj_settings = $59
!obj_num = $5A 
!map16_low = [$6B]
!map16_high = [$6E]
!obj_screen = $1928|!addr
!tileset = $1931|!addr
!tile_screen = $1BA1|!addr

!EXLEVEL = 0
if (((read1($0FF0B4)-'0')*100)+((read1($0FF0B4+2)-'0')*10)+(read1($0FF0B4+3)-'0')) > 253
	!EXLEVEL = 1
endif

; Macro for calling SNES CPU. Label should point to a routine which ends in RTL.
; Data bank is not set, so use PHB/PHK/PLB ... PLB in your SNES code.
macro invoke_snes(addr)
	LDA.b #<addr>
	STA $0183
	LDA.b #<addr>/256
	STA $0184
	LDA.b #<addr>/65536
	STA $0185
	LDA #$D0
	STA $2209
-	LDA $018A
	BEQ -
	STZ $018A
endmacro

; Same as invoke_snes except for SA-1, object code runs at SA-1 already, so you'll likely never need to use this.
macro invoke_sa1(label)
	LDA.b #<label>
	STA $3180
	LDA.b #<label>>>8
	STA $3181
	LDA.b #<label>>>16
	STA $3182
	JSR $1E80
endmacro
