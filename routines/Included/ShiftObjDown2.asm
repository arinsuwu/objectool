;------------------------------------------------
; allow an object to go across subscreen boundaries vertically
; shifts a customizable number of tiles (input in A)
;------------------------------------------------

main:
	ASL #4
	STA $0E
	LDA $57
	CLC
	ADC $0E
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
	CLC
	ADC #$02
	STA $6C
	STA $6F
	INC $1BA1|!addr
	RTL