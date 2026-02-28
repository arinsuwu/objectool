;------------------------------------------------
; back up the low and high byte of the Map16 pointers in scratch RAM (ripped from $0DA6B1)
; also includes a call point for a typical object initialization routine
;------------------------------------------------

main:
	%StoreNybbles()
	LDY $57
	LDA $08
	STA $00
	STA $02
	LDA $09
	STA $01
	LDA $6B
	STA $04
	LDA $6C
	STA $05
	RTL