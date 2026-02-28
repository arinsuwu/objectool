;------------------------------------------------
; object that can only be stretched in one direction and is 2 tiles wide
; make an object that can be stretched in one direction only and checks which direction that is
; To be inserted as a normal object.
;
; The extra byte determines which table to use.
;
; Note: Currently, stretching it in both directions or not at all will just cause it to return without creating any tiles.
;------------------------------------------------

UnidimensionalObjTilesWide:
	dw $021C,$021D
	dw $022C,$022D
	dw $022E,$022F
	
load:
	LDA !extra_byte
	REP #$30
	AND #$00FF
	ASL
	STA $00
	ASL
	ADC $00
	ASL
	TAX
	LDA.w UnidimensionalObjTilesWide,x
	STA !ObjScratch
	LDA.w UnidimensionalObjTilesWide+2,x
	STA !ObjScratch+$02
	LDA.w UnidimensionalObjTilesWide+4,x
	STA !ObjScratch+$04
	LDA.w UnidimensionalObjTilesWide+6,x
	STA !ObjScratch+$06
	LDA.w UnidimensionalObjTilesWide+8,x
	STA !ObjScratch+$08
	LDA.w UnidimensionalObjTilesWide+10,x
	STA !ObjScratch+$0A
	SEP #$30
	%StoreNybbles()
	LDY !obj_pos
	LDA $08
	STA $00
	STA $02
	LDA $09
	STA $01
	%BackUpPtrs()
	LDA $09
	BEQ .Horiz
	LDA $08
	BEQ .Vert
; both H and V?
	RTS
.Zero
; neither H nor V?
	RTS
.Horiz
	LDA $08
	BEQ .Zero
	STZ !ObjScratch+$0C
.LoopH2
	LDX !ObjScratch+$0C
	REP #$20
	LDA !ObjScratch,x
	STA $0A
	LDA !ObjScratch+$02,x
	STA $0C
	LDA !ObjScratch+$04,x
	STA $0E
	SEP #$20
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
	LDA !ObjScratch+$0C
	BNE .ReturnH
	CLC
	ADC #$06
	STA !ObjScratch+$0C
	%RestorePtrs()
	%ShiftObjDown()
	BRA .LoopH2
.ReturnH
	RTS
.Vert
	LDA $09
	BEQ .Zero
	LDA !ObjScratch
	STA !map16_low,y
	LDA !ObjScratch+$01
	STA !map16_high,y
	%ShiftObjRight()
	LDA !ObjScratch+$02
	STA !map16_low,y
	LDA !ObjScratch+$03
	STA !map16_high,y
	LDX $09
	BRA .EndV
.LoopV
	LDA !ObjScratch+$04
	STA !map16_low,y
	LDA !ObjScratch+$05
	STA !map16_high,y
	%ShiftObjRight()
	LDA !ObjScratch+$06
	STA !map16_low,y
	LDA !ObjScratch+$07
	STA !map16_high,y
.EndV
	%ShiftObjDown()
	DEX
	BNE .LoopV
	LDA !ObjScratch+$08
	STA !map16_low,y
	LDA !ObjScratch+$09
	STA !map16_high,y
	%ShiftObjRight()
	LDA !ObjScratch+$0A
	STA !map16_low,y
	LDA !ObjScratch+$0B
	STA !map16_high,y
	RTS
