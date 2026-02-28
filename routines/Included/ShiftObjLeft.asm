;------------------------------------------------
; allow an object to go across screen boundaries backward horizontally
;------------------------------------------------

main:
	DEY
	TYA
	AND #$0F
	CMP #$0F
	BNE .NoScreenChange
	LDA $5B
	LSR
	BCS .VertLvl
	REP #$20
	LDA $6B
	SEC
	SBC $13D7|!addr
	STA $6B
	STA $6E
	SEP #$20
	DEC $1BA1|!addr
	LDA $57
	AND #$F0
	ORA #$0F
	TAY
.NoScreenChange
	RTL
.VertLvl
	DEC $6C
	DEC $6F
	LDA $57
	AND #$F0
	ORA #$0F
	TAY
	RTL