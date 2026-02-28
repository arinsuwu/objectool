;------------------------------------------------
;	An object consisting of 3 blocks that can be stretched horizontally only
;   To be inserted as a normal object.
;	
;   The extra byte determines which table to use.
;
;	The horizontal and vertical 2-ended objects use tables of 4 tiles each,
;	the first for the left or top end, the second for the middle, the third for the right or bottom end,
;	and the fourth for when the object is only a single block.
;------------------------------------------------

Horiz2EndTiles:
	dw $020C,$020D,$020E : dw $021F
	
load:
	LDA !obj_settings
	AND #$0F
	STA $08
	LDA !extra_byte
	LDY !obj_pos
	REP #$30
	AND.w #$00FF
	ASL #3
	TAX
	LDA $08
	AND #$00FF
	BNE .NotSingleTile
	LDA.w Horiz2EndTiles+6,x
	STA $0E
	SEP #$30
	BRA .StoreOnlyOne
.NotSingleTile
	LDA.w Horiz2EndTiles+4,x
	STA $0E
	LDA.w Horiz2EndTiles+2,x
	STA $0C
	LDA.w Horiz2EndTiles,x
	SEP #$30
	STA !map16_low,y
	XBA
	STA !map16_high,y
	LDX $08
	BRA .End
.Loop
	LDA $0C
	STA !map16_low,y
	LDA $0D
	STA !map16_high,y
.End
	%ShiftObjRight()
	DEX
	BNE .Loop
	LDA $0E
.StoreOnlyOne
	STA !map16_low,y
	LDA $0F
	STA !map16_high,y
	RTS