;------------------------------------------------
; shift the current tile position index up
; reset the X position
; input: A (16-bit) = number of tiles to shift
;------------------------------------------------

main:
	AND #$00FF
	ASL #4
	STA $0E
	LDA $5B
	LSR
	BCS .Vertical
	TYA
	SEC
	SBC $0E
	TAY
	LDA $04
	INC
	%CustObjShiftLeft()
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
	LDA $04
	INC
	%CustObjShiftLeft()
	RTL