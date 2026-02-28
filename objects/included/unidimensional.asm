;------------------------------------------------
; Make an object that can be stretched in one direction only and checks which direction that is
; To be inserted as a normal object.
;
; The extra byte determines which table to use.
;
; Note: Currently, stretching it in both directions will just cause it to return without creating any tiles.
;------------------------------------------------

UnidimensionalObjTiles:
	dw $020B
	dw $021B
	dw $022B
	
	dw $020F

UnidimensionalObjTiles2:
	dw $020C,$020D,$020E : dw $021F

load:
	LDA !extra_byte
	REP #$30
	AND #$00FF
	ASL #3
	TAX
	LDA.w UnidimensionalObjTiles,x
	STA $0A
	LDA.w UnidimensionalObjTiles+2,x
	STA $0C
	LDA.w UnidimensionalObjTiles+4,x
	STA $0E
	SEP #$30
	%StoreNybbles()
	LDY !obj_pos
	LDA $09
	BEQ .Horiz
	LDA $08
	BEQ .Vert
; both H and V?
	RTS
.Zero
	LDA.w UnidimensionalObjTiles+6,x
	STA !map16_low,y
	LDA.w UnidimensionalObjTiles+7,x
	STA !map16_high,y
	RTS
.Horiz
	LDA $08
	BEQ .Zero
	LDA $0A
	STA !map16_low,y
	LDA $0B
	STA !map16_high,y
	LDX $08
	BRA .EndH
.LoopH
	LDA $0C
	STA !map16_low,y
	LDA $0D
	STA !map16_high,y
.EndH
	%ShiftObjRight()
	DEX
	BNE .LoopH
	LDA $0E
	STA !map16_low,y
	LDA $0F
	STA !map16_high,y
	RTS
.Vert
	LDA $09
	BEQ .Zero
	LDA $0A
	STA !map16_low,y
	LDA $0B
	STA !map16_high,y
	LDX $09
	BRA .EndV
.LoopV
	LDA $0C
	STA !map16_low,y
	LDA $0D
	STA !map16_high,y
.EndV
	%ShiftObjDown()
	DEX
	BNE .LoopV
	LDA $0E
	STA !map16_low,y
	LDA $0F
	STA !map16_high,y
	RTS
