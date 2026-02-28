;------------------------------------------------
; For this system:
; - 16-bit AXY most of the time (A can be switched to 8-bit mode, but XY should ALWAYS be left as 16-bit because Y indexes the Map16 pointers)
; - Y = index to Map16 data (is a multiple of $13D7|!addr or #$0200 plus an object's position within a screen or column of screens)
; $57: unused? (originally object position within the subscreen (yyyyxxxx))
; $58: normal object extra settings byte
; $59: normal object size/extended object number
; $5A: normal object number
; $00-$01: screen height (is the value of $13D7|!addr for horizontal levels and #$0100 for vertical ones)
; $02-$03: object initial position index
; $04-$05: object width
; $06-$07: object height
; $08-$09: counter for object width
; $0A-$0B: counter for object height
; $0C-$0F: scratch
;------------------------------------------------

main:
	LDA $59
	AND #$0F
	STA $04
	STZ $05
	LDA $59
	LSR #4
	STA $06
	STZ $07
	LDA $0A
	AND #$10
	LSR #4
	STA $0F
	LDA $5B
	LSR
	BCS .Vertical
	LDA $8B
	ORA $0F
	STA $09
	LDA $57
	STA $08
	if !sa1
		STZ $2250
	endif
	REP #$30
	LDA $13D7|!addr
	CMP #$0FF0
	BCC .MultiplyScreen
	LDY $08
	CMP #$12A0
	BEQ .Mode1A
	CMP #$1C00
	BNE .Shared
.Mode1B
	LDA $1BA1|!addr
	AND #$00FF
	BEQ .Shared
	TYA
	CLC
	ADC #$1C00
	TAY
	BRA .Shared
.Mode1A
	LDA $1BA1|!addr
	AND #$00FF
	DEC
	BMI .Shared
	BNE .Mode1AScreen02
.Mode1AScreen01
	TYA
	CLC
	ADC #$12A0
	TAY
	BRA .Shared
.Mode1AScreen02
	TYA
	CLC
	ADC #$2540
	TAY
	BRA .Shared
.MultiplyScreen
	LSR #4
	if !sa1
		AND #$00FF
		STA $2251
		LDA $1BA1|!addr
		AND #$00FF
		STA $2253
		NOP
		LDA $2306
	else
		SEP #$20
		STA $4202
		LDA $1BA1|!addr
		STA $4203
		PHA
		PLA
		REP #$30
		LDA $4216
	endif
	ASL #4
	ADC $08
	TAY
	BRA .Shared
.Vertical
	LDA $57
	STA $0E
	LDA $1BA1|!addr
	if !sa1
		REP #$30
		AND #$00FF
		STA $2251
		LDA #$0020
		STA $2253
		NOP
		LDA $2306
	else
		STA $4202
		LDA #$20
		STA $4203
		REP #$30
		LDA #$0100
		STA $00
		LDA $4216
	endif
	ASL #4
	ADC $0E
	TAY
.Shared
	STA $02
	LDA #$C800
	STA $6B
	LDA #$0000|!map16
	STA $6D
	LDA #$00C8|((!map16|$01)<<8)
	STA $6F
	LDA $04
	STA $08
	LDA $06
	STA $0A
	LDA $13D7|!addr
	STA $00
	RTL