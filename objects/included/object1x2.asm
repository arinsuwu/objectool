;------------------------------------------------
; Make an object consisting of a 1x2 rectangle
; To be inserted as an extended object.
;
; The parameter word determines which blocks to use.
;------------------------------------------------

Obj1x2Tiles:
	dw $0203
	dw $0223
	
load:
	ASL
	TAX
	LDA parameterWordsEx,x
	ASL #2
	TAX
	LDY !obj_pos
	LDA.w Obj1x2Tiles,x
	STA !map16_low,y
	LDA.w Obj1x2Tiles+1,x
	STA !map16_high,y
	INX #2
	%ShiftObjDown()
	LDA.w Obj1x2Tiles,x
	STA !map16_low,y
	LDA.w Obj1x2Tiles+1,x
	STA !map16_high,y
	RTS