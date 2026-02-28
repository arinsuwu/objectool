;------------------------------------------------
; shift the current tile position index left
; input: A (16-bit) = number of tiles to shift
;------------------------------------------------

main:
	STA $0E
.Check
	CMP #$0011
	BCC .Run
	PHA
	TYA
	SEC
	SBC $00
	TAY
	PLA
	SEC
	SBC #$0010
	STA $0E
	BRA .Check
.Run
	LDA $5B
	LSR
	BCS .Vertical
	TYA
	PHA
	SEC
	SBC $0E
	TAY
	PLA
	AND #$000F
	SEC
	SBC $0E
	BPL .NoScreenChange
	TYA
	CLC
	ADC #$0010
	SEC
	SBC $00
	TAY
.NoScreenChange
	RTL
.Vertical
	TYA
	PHA
	SEC
	SBC $0E
	TAY
	PLA
	AND #$000F
	SEC
	SBC $0E
	BPL .NoScreenChange
	TYA
	SEC
	SBC #$00F0
	TAY
	RTL