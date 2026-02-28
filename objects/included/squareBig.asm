;------------------------------------------------
; Make an object consisting of 9 blocks that can be stretched.
; To be inserted as a normal object.
;
; The parameter word determines which table to use.
;
; The extra byte is used for 8 extra size bits (yyyyxxxx)
; This allows the square to extend beyond a single screen.
;
; So assuming the settings byte is (YYYYXXXX)
; The square's width would be xxxxXXXX, and height yyyyYYYY.
;
; The square objects use tables of 16 Map16 tiles each.
; The first 9 are for the top-left corner, top ledge, top-right corner, left edge, middle, right edge, bottom-left corner, bottom edge, and bottom right corner
; in that order when the object is larger than 1 block in both directions.
; The next 3 are for the left end, middle, and right end when the object is only 1 tile tall but more than 1 tile wide.
; The next 3 are for the top end, middle, and bottom end when the object is only 1 tile wide but more than 1 tile tall.
;
; The last one is for when the object is only a single block.
; The alternative versions of both the big and normal square objects use the same format, but there are two tables instead of one;
; the second one is for the "filled-in" version of the tiles when part or all of the object is placed above a non-blank tile.
;------------------------------------------------

SquareObjTiles:
	dw $0200,$0201,$0202
	dw $0210,$0211,$0212
	dw $0220,$0221,$0222
	
	dw $0230,$0231,$0232
	
	dw $0203
	dw $0213
	dw $0223
	
	dw $0233
	
load:
	REP #$30
	AND #$00FF
	ASL
	TAX
	LDA parameterWords,x
	SEP #$10
	AND.w #$00FF
	ASL #4
	STA $0C
	SEP #$20
	%StoreNybbles()
	LDA !extra_byte
	ASL #4
	TSB $08
	LDA !extra_byte
	AND #$F0
	TSB $09
	LDY !obj_pos
	LDA $08
	STA $00
	LDA $09
	STA $01
	%BackUpPtrs()
	LDA $09
	BEQ .NoVert
	LDA $08
	BEQ .VertOnly
	JMP .StartObjLoop
.VertOnly
	REP #$30
	LDA $0C
	CLC
	ADC #$000C
	STA $0C
	SEP #$20
.LoopV
	LDX $0C
	LDA $01
	CMP $09
	BEQ .SetTileIndexV
	INX
	CMP #$00
	BNE .SetTileIndexV
	INX
.SetTileIndexV
	REP #$20
	TXA
	ASL
	TAX
	LDA.w SquareObjTiles,x
	SEP #$30
	STA !map16_low,y
	XBA
	STA !map16_high,y
	%ShiftObjDown()
	DEC $01
	BPL .LoopV
	RTS
.NoVert
	LDA $08
	BEQ .SingleTile
.HorizOnly
	REP #$30
	LDA $0C
	CLC
	ADC #$0009
	STA $0C
	SEP #$20
.LoopH
	LDX $0C
	LDA $00
	CMP $08
	BEQ .SetTileIndexH
	INX
	CMP #$00
	BNE .SetTileIndexH
	INX
.SetTileIndexH
	REP #$20
	TXA
	ASL
	TAX
	LDA.w SquareObjTiles,x
	SEP #$30
	STA !map16_low,y
	XBA
	STA !map16_high,y
	%ShiftObjRight()
	DEC $00
	BPL .LoopH
	RTS
.SingleTile
	REP #$30
	LDA $0C
	CLC
	ADC #$000F
	ASL
	TAX
	LDA.w SquareObjTiles,x
	SEP #$30
	STA !map16_low,y
	XBA
	STA !map16_high,y
	RTS
.StartObjLoop
	REP #$10
	LDX $0C
	LDA $01
	CMP $09
	BEQ .NoInc1
	INX #3
	CMP #$00
	BNE .NoInc1
	INX #3
.NoInc1
	LDA $00
	CMP $08
	BEQ .SetTileIndex
	INX
	CMP #$00
	BNE .SetTileIndex
	INX
.SetTileIndex
	REP #$20
	TXA
	ASL
	TAX
	LDA.w SquareObjTiles,x
	SEP #$30
	STA !map16_low,y
	XBA
	STA !map16_high,y
	%ShiftObjRight()
.DecAndLoop
	DEC $00
	BPL .StartObjLoop
	%RestorePtrs()
	%ShiftObjDown()
	LDA $08
	STA $00
	DEC $01
	BMI .EndObjLoop
	JMP .StartObjLoop
.EndObjLoop
.Return
	RTS