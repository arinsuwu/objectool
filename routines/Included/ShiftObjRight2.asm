;------------------------------------------------
; allow an object to go across screen boundaries horizontally
; shifts a customizable number of tiles (input in A)
;------------------------------------------------

main:
	STA $0E
.Check
	CMP #$11
	BCC .Run
	PHA
	REP #$20
	LDA $6B
	CLC
	ADC $13D7|!addr
	STA $6B
	STA $6E
	SEP #$20
	INC $1BA1|!addr
	PLA
	SEC
	SBC #$10
	STA $0E
	BRA .Check
.Run
	LDA $57
	AND #$0F
	STA $0F
	CLC
	ADC $0E
	CMP #$10
	AND #$0F
	STA $0F
	BCC .NoScreenChange
	LDA $5B
	AND #$01
	BNE .VertLvl
	REP #$20
	LDA $6B
	ADC $13D7|!addr
	STA $6B
	STA $6E
	SEP #$20
	INC $1BA1|!addr
.NoScreenChange
	LDA $57
	AND #$F0
	ORA $0F
	STA $57
	TAY
	RTL
.VertLvl
	INC $6C
	INC $6F
	LDA $57
	AND #$F0
	ORA $0F
	TAY
	RTL