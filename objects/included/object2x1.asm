;------------------------------------------------
; Make an object consisting of a 2x1 rectangle
; To be inserted as an extended object.
;
; The parameter word determines which blocks to use.
;------------------------------------------------

Obj2x1Tiles:
	dw $0230,$0232
	
load:
	ASL
	TAX
	LDA parameterWordsEx,x
	ASL #2
	TAX
	LDY !obj_pos
	LDA.w Obj2x1Tiles,x
	STA !map16_low,y
	LDA.w Obj2x1Tiles+1,x
	STA !map16_high,y
	INX #2
	%ShiftObjRight()
	LDA.w Obj2x1Tiles,x
	STA !map16_low,y
	LDA.w Obj2x1Tiles+1,x
	STA !map16_high,y
	RTS
