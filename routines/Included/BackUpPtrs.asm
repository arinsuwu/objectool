;------------------------------------------------
; back up the low and high byte of the Map16 pointers in scratch RAM (ripped from $0DA6B1)
;------------------------------------------------

main:
	LDA $6B
	STA $04
	LDA $6C
	STA $05
	RTL