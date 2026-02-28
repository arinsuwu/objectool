;------------------------------------------------
; shift the current tile position index right
; input: A (16-bit) = number of tiles to shift
;------------------------------------------------

main:
	STA $0E
.Check
	CMP #$0011
	BCC .Run
	PHA
	TYA
	CLC
	ADC $00
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
	CLC
	ADC $0E
	TAY
	PLA
	AND #$000F
	CLC
	ADC $0E
	CMP #$0010
	BCC .NoScreenChange
	TYA
	SEC
	SBC #$0010
	CLC
	ADC $00
	TAY
.NoScreenChange
	RTL
.Vertical
	TYA
	PHA
	CLC
	ADC $0E
	TAY
	PLA
	AND #$000F
	CLC
	ADC $0E
	CMP #$0010
	BCC .NoScreenChange
	TYA
	CLC
	ADC #$00F0
	TAY
	RTL