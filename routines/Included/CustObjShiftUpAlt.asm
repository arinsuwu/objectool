;------------------------------------------------
; shift the current tile position index up
; do not reset the X position
; input: A (16-bit) = number of tiles to shift
;------------------------------------------------

main:
	ASL #4
	STA $0E
	LDA $5B
	LSR
	BCS .Vertical
	TYA
	SEC
	SBC $0E
	TAY
	RTL
.Vertical
	PHY
	TYA
	SEC
	SBC $0E
	TAY
	EOR $01,s
	AND #$0100
	BEQ .NoScreenChange
	TYA
	SEC
	SBC #$0100
	TAY
.NoScreenChange
	PLA
	RTL