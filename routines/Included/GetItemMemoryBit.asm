;------------------------------------------------
; check item memory for a particular block position (ripped from $0DA8DC)
; Output: A will be 0 if the item memory bit is not set and nonzero if it is set.
;------------------------------------------------

main:
	PHX
	PHY
	LDX $13BE|!addr
	LDA #$F8
	CLC
	ADC $0DA8AE|!bank,x
	STA $08
	LDA.b #$19|(!addr>>8)
	ADC $0DA8B1|!bank,x
	STA $09
	LDA $1BA1|!addr
	ASL #2
	STA $0E
	LDA $0A
	AND #$10
	BEQ .UpperSubscreen
	LDA $0E
	ORA #$02
	STA $0E
.UpperSubscreen
	TYA
	AND #$08
	BEQ .LeftHalfOfScreen
	LDA $0E
	ORA #$01
	STA $0E
.LeftHalfOfScreen
	TYA
	AND #$07
	TAX
	LDY $0E
	LDA ($08),y
	AND $0DA8A6|!bank,x
	PLY
	PLX
	CMP #$00
	RTL