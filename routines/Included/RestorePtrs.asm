;------------------------------------------------
; restore the low and high byte of the Map16 pointers from scratch RAM (ripped from $0DA6BA)
;------------------------------------------------

main:
	LDA $04
	STA $6B
	STA $6E
	LDA $05
	STA $6C
	STA $6F
	LDA $1928|!addr
	STA $1BA1|!addr
	RTL