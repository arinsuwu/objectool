;------------------------------------------------
; allow an object to go across screen boundaries backward horizontally
; shifts a customizable number of tiles (input in A)
;------------------------------------------------

main:
	STA $0E
	LDA $57
	AND #$0F
	STA $0F
	SEC
	SBC $0E
	CMP #$10
	AND #$0F
	STA $0F
	BCC .NoScreenChange
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
.NoScreenChange
	LDA $57
	AND #$F0
	ORA $0F
	STA $57
	RTL
.VertLvl
	DEC $6C
	DEC $6F
	LDA $57
	AND #$F0
	ORA #$0F
	TAY
	RTL