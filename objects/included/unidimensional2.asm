;------------------------------------------------
; Make an object that can be stretched in one direction only and checks which direction that is
; Also checks for overlap with specific other tiles and changes the spawned tile accordingly
; To be inserted as a normal object.
;
; The extra byte determines which table to use.
;
; Note: Currently, stretching it in both directions will just cause it to return without creating any tiles.
;------------------------------------------------
	
UnidimensionalObjTiles2:
	dw $020C,$020D,$020E : dw $021F
	
UnidimensionalObjCheckTiles:
	dw $0000,$021B,$0000 : dw $0000

UnidimensionalObjReplaceTiles:
	dw $0000,$021E,$0000 : dw $0000
	
load:
	LDA !extra_byte
	REP #$30
	AND #$00FF
	ASL #3
	TAX
	LDA.w UnidimensionalObjTiles2,x
	STA $0A
	LDA.w UnidimensionalObjTiles2+2,x
	STA $0C
	LDA.w UnidimensionalObjTiles2+4,x
	STA $0E
	LDA.w UnidimensionalObjCheckTiles,x
	STA $45
	LDA.w UnidimensionalObjCheckTiles+2,x
	STA $47
	LDA.w UnidimensionalObjCheckTiles+4,x
	STA $49
	LDA.w UnidimensionalObjReplaceTiles,x
	STA !ObjScratch
	LDA.w UnidimensionalObjReplaceTiles+2,x
	STA !ObjScratch+2
	LDA.w UnidimensionalObjReplaceTiles+4,x
	STA !ObjScratch+4
	LDA.w UnidimensionalObjTiles2+6,x
	STA !ObjScratch+6
	LDA.w UnidimensionalObjCheckTiles+6,x
	STA !ObjScratch+8
	LDA.w UnidimensionalObjReplaceTiles+6,x
	STA !ObjScratch+10
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
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	CMP !ObjScratch+8
	BEQ .ReplaceZero
	LDA !ObjScratch+6
	BRA .StoreTileZero
.ReplaceZero
	LDA !ObjScratch+10
.StoreTileZero
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	RTS
.Horiz
	LDA $08
	BEQ .Zero
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	CMP $45
	BEQ .Replace1H
	LDA $0A
	BRA .SetTile1H
.Replace1H
	LDA !ObjScratch
.SetTile1H
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	LDX $08
	BRA .EndH
.LoopH
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	CMP $47
	BEQ .Replace2H
	LDA $0C
	BRA .SetTile2H
.Replace2H
	LDA !ObjScratch+2
.SetTile2H
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
.EndH
	%ShiftObjRight()
	DEX
	BNE .LoopH
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	CMP $49
	BEQ .Replace3H
	LDA $0E
	BRA .SetTile3H
.Replace3H
	LDA !ObjScratch+4
.SetTile3H
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	RTS
.Vert
	LDA $09
	BEQ .Zero
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	CMP $45
	BEQ .Replace1V
	LDA $0A
	BRA .SetTile1V
.Replace1V
	LDA !ObjScratch
.SetTile1V
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	LDX $09
	BRA .EndV
.LoopV
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	CMP $47
	BEQ .Replace2V
	LDA $0C
	BRA .SetTile2V
.Replace2V
	LDA !ObjScratch+2
.SetTile2V
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
.EndV
	%ShiftObjDown()
	DEX
	BNE .LoopV
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	CMP $49
	BEQ .Replace3V
	LDA $0E
	BRA .SetTile3V
.Replace3V
	LDA !ObjScratch+4
.SetTile3V
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	RTS
