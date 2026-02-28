;------------------------------------------------
; allow an object to go across subscreen boundaries vertically (adapted from $0DA97D)
;------------------------------------------------

main:
	LDA $57
	CLC
	ADC #$10
	STA $57
	TAY
	BCC .NoScreenChange
	LDA $5B
	AND #$01
	BNE .VertLvl
	LDA $6C
	ADC #$00
	STA $6C
	STA $6F
	STA $05
.NoScreenChange
	RTL
.VertLvl
	LDA $6C
	ADC #$01
	STA $6C
	STA $6F
	INC $1BA1|!addr
	RTL