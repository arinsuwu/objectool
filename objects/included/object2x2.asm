;------------------------------------------------
; Make an object consisting of a 2x2 square
; To be inserted as an extended object.
;
; The parameter word determines which blocks to use.
;------------------------------------------------

Obj2x2Tiles:
	dw $0200,$0202
	dw $0220,$0222
	
load:
	ASL
	TAX
	LDA parameterWordsEx,x
	ASL #3
	TAX
	%BackUpPtrs()
	LDY !obj_pos
	LDA.w Obj2x2Tiles,x
	STA !map16_low,y
	LDA.w Obj2x2Tiles+1,x
	STA !map16_high,y
	INX #2
	%ShiftObjRight()
	LDA.w Obj2x2Tiles,x
	STA !map16_low,y
	LDA.w Obj2x2Tiles+1,x
	STA !map16_high,y
	%RestorePtrs()
	%ShiftObjDown()
	INX #2
	LDA.w Obj2x2Tiles,x
	STA !map16_low,y
	LDA.w Obj2x2Tiles+1,x
	STA !map16_high,y
	INX #2
	%ShiftObjRight()
	LDA.w Obj2x2Tiles,x
	STA !map16_low,y
	LDA.w Obj2x2Tiles+1,x
	STA !map16_high,y
	RTS