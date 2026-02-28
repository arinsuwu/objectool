;------------------------------------------------
; Make an object consisting of a single block
; To be inserted as an extended object.
;
; The parameter word determines which blocks to use.
;------------------------------------------------

Obj1x1Tiles:
	dw $0233
	
load:
	REP #$30
	AND #$00FF
	ASL
	TAX
	LDA parameterWordsEx,x
	SEP #$30
	ASL
	TAX
	LDY !obj_pos
	LDA.w Obj1x1Tiles,x
	STA !map16_low,y
	LDA.w Obj1x1Tiles+1,x
	STA !map16_high,y
	RTS