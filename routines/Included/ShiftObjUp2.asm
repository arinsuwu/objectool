;------------------------------------------------
; allow an object to go across subscreen boundaries backward vertically
; shifts a customizable number of tiles (input in A)
;------------------------------------------------

main:
	LDA $57
	SEC
	SBC #$10
	STA $57
	TAY
	BCS .NoScreenChange
	LDA $5B
	AND #$01
	BNE .VertLvl
	LDA $6C
	SBC #$00
	STA $6C
	STA $6F
	STA $05
.NoScreenChange
	RTL
.VertLvl
	LDA $6C
	SEC
	SBC #$02
	STA $6C
	STA $6F
	DEC $1BA1|!addr
	RTL