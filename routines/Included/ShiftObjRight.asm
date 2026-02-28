;------------------------------------------------
; allow an object to go across screen boundaries horizontally (adapted from $0DA95B)
;------------------------------------------------

main:
	INY
	TYA
	AND #$0F
	BNE .NoScreenChange
	LDA $5B
	LSR
	BCS .VertLvl
	REP #$21
	LDA $6B
	ADC $13D7|!addr
	STA $6B
	STA $6E
	LDA #$0000
	SEP #$20
	INC $1BA1|!addr
	LDA $57
	AND #$F0
	TAY
.NoScreenChange
	RTL
.VertLvl
	INC $6C
	INC $6F
	LDA $57
	AND #$F0
	TAY
	RTL