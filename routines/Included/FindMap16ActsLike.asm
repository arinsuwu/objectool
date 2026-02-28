;------------------------------------------------
; find the acts-like setting of the tile at the current position (or a specified tile number)
;------------------------------------------------

main:
	PHP
	SEP #$20
	LDA [$6E],y
	XBA
	LDA [$6B],y
FindMap16ActsLikeEntry1:
	REP #$20
.Loop
	ASL
	ADC $06F624|!bank
	STA $0D
	SEP #$20
	LDA $06F626|!bank
	STA $0F
	REP #$20
	LDA [$0D]
	CMP #$0200
	BCS .Loop
	PLP
	RTL