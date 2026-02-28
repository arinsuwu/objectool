;------------------------------------------------
;   Make an object consisting of 3 blocks that can be stretched vertically only
;   To be inserted as a normal object.
;	
;   The extra byte determines which table to use.
;
;	The horizontal and vertical 2-ended objects use tables of 4 tiles each,
;	the first for the left or top end, the second for the middle, the third for the right or bottom end,
;	and the fourth for when the object is only a single block.
;------------------------------------------------

Vert2EndTiles:
	dw $020B
	dw $021B
	dw $022B
	
	dw $020F
	
load:
	LDA !extra_byte
	LDY !obj_pos
	REP #$30
	AND.w #$00FF
	ASL #3
	TAX
	LDA $09
	AND #$00FF
	BNE .NotSingleTile
	LDA.w Vert2EndTiles+6,x
	STA $0E
	SEP #$30
	BRA .StoreOnlyOne
.NotSingleTile
	LDA.w Vert2EndTiles+4,x
	STA $0E
	LDA.w Vert2EndTiles+2,x
	STA $0C
	LDA.w Vert2EndTiles,x
	SEP #$30
	STA !map16_low,y
	XBA
	STA !map16_high,y
	LDX $09
	BRA .End
.Loop
	LDA $0C
	STA !map16_low,y
	LDA $0D
	STA !map16_high,y
.End
	%ShiftObjDown()
	DEX
	BNE .Loop
	LDA $0E
.StoreOnlyOne
	STA !map16_low,y
	LDA $0F
	STA !map16_high,y
	RTS