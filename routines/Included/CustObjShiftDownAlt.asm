;------------------------------------------------
; shift the current tile position index down
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
	CLC
	ADC $0E
	TAY
	RTL
.Vertical
	PHY
	TYA
	CLC
	ADC $0E
	TAY
	EOR $01,s
	AND #$0100
	BEQ .NoScreenChange
	TYA
	CLC
	ADC #$0100
	TAY
.NoScreenChange
	PLA
	RTL