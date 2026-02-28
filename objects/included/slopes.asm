;------------------------------------------------
;   make a slope object (this routine handles all of the different slopes)
;   this object has 10 variations that depend on the parameter's value.
;   To be inserted as a normal object.
;
;   Input:
;   The parameter word indicates the slope type. The types are:
;   - 0 steep left
;   - 1 steep right
;   - 2 normal left
;   - 3 normal right
;   - 4 gradual left
;   - 5 gradual right
;   - 6 upside-down steep left
;   - 7 upside-down steep right
;   - 8 upside-down normal left
;   - 9 upside-down normal right
;
;   The extra byte indicates the tilemap data index (basically, think of this as the tileset number).
;
;   The slope objects are quite complex.
;   They depend on lists of Map16 numbers for the different slope types.
;   The sample tilemap data has a table of pointers, and at the location of each pointer is a table of offsets followed by Map16 tile numbers.
;   There are four example tables here, each of a different size.
;   The offsets indicate where the data for each slope starts relative to the pointer.
;   At maximum, the table can have 11 offsets and all 10 slope types.
;   The first offset is for the fill tile, then there are two for the steep slopes, two for the normal ones,
;   two for the gradual ones, two for the upside-down steep ones, and two for the upside-down normal ones.
;   The example tables are organized such that each line of Map16 tile numbers corresponds to an offset and, except for the first one, a slope type.
;   The order of the tile numbers is all the tiles on the top of the slope, then the tiles below them, then the filled-in top tiles.
;   For instance, a normal slope has 2 top tiles, 2 bottom tiles, and 2 filled-in tiles, for a total of 6.
;   You can see this in the first example table, which has all of the tiles for the original game's slope objects
;   (though SMW doesn't normally have filled-in upside-down slopes, so those are left as 0000).
;   You can also leave out some slope types if a particular tileset lacks them, which is shown by the other three example tables.
;   The second table has no gradual slopes, though note that they still require bytes in the offset table because there is data after them;
;   the two $FF bytes correspond to the offsets for the gradual slopes, but these could be anything because they are never read (or, at least, they shouldn't be).
;   The third table is missing both gradual slopes and upside-down slopes.
;   Note that here, the offset table can be truncated because all of the missing slopes are in a row at the end of the table.
;   The fourth table has only steep and normal slopes like the third, but it also lacks filled-in tiles, so the lines only have
;   2 and 4 tile numbers rather than 3 and 6 (notice that this also changes most of the offsets).
;   When placing these in Lunar Magic, stretching them horizontally will make the slope bigger, and stretching them vertically will create more fill tiles below the slope.
;------------------------------------------------

SlopeTypePointers:
	dw SlopeSteepL
	dw SlopeSteepR
	dw SlopeNormalL
	dw SlopeNormalR
	dw SlopeGradualL
	dw SlopeGradualR
	dw SlopeUpsideDownSteepL
	dw SlopeUpsideDownSteepR
	dw SlopeUpsideDownNormalL
	dw SlopeUpsideDownNormalR
	
SlopeDataSize:
	db $06,$06,$0C,$0C,$18,$18,$06,$06,$0C,$0C

; fill tile,
; steep left, steep right,
; normal left, normal right,
; gradual left, gradual right,
; upside-down steep left, upside-down steep right,
; upside-down normal left, upside-down normal right
; also filled-in tiles at the end of each row

SlopeTilemapData:
	dw .00,.01,.02,.03
.00
	db $0B,$0D,$13,$19,$25,$31,$49,$61,$67,$6D,$79
	dw $003F
	dw $01AA,$01E2,$01AB
	dw $01AF,$01E4,$01B0
	dw $0196,$019B,$01DE,$003F,$0197,$019C
	dw $01A0,$01A5,$003F,$01E0,$01A1,$01A6
	dw $016E,$0173,$0178,$017D,$01D8,$01DA,$01E6,$01E6,$016F,$0174,$0179,$017E
	dw $0182,$0187,$018C,$0191,$01E6,$01E6,$01DB,$01DC,$0183,$0188,$018D,$0192
	dw $01EC,$01C4,$0000
	dw $01ED,$01C5,$0000
	dw $01EE,$003F,$01C6,$01C7,$0000,$0000
	dw $003F,$01EF,$01C8,$01C9,$0000,$0000
.01
	db $0B,$0D,$13,$19,$25,$FF,$FF,$31,$37,$3D,$49
	dw $0000
	dw $0000,$0000,$0000
	dw $0000,$0000,$0000
	dw $0000,$0000,$0000,$0000,$0000,$0000
	dw $0000,$0000,$0000,$0000,$0000,$0000
	dw $0000,$0000,$0000
	dw $0000,$0000,$0000
	dw $0000,$0000,$0000,$0000,$0000,$0000
	dw $0000,$0000,$0000,$0000,$0000,$0000
.02
	db $05,$07,$0D,$13,$1F
	dw $0000
	dw $0000,$0000,$0000
	dw $0000,$0000,$0000
	dw $0000,$0000,$0000,$0000,$0000,$0000
	dw $0000,$0000,$0000,$0000,$0000,$0000
.03
	db $05,$07,$0B,$0F,$17
	dw $0000
	dw $0000,$0000
	dw $0000,$0000
	dw $0000,$0000,$0000,$0000
	dw $0000,$0000,$0000,$0000
	
load:
	REP #$30
	AND #$00FF
	ASL
	TAX
	LDA parameterWords,x
	SEP #$30
	LDY !extra_byte
	STA $00
	TYA
	ASL
	TAY
	REP #$20
	LDA SlopeTilemapData,y
	STA $01
	LDY $00
	INY
	LDA ($01),y
	STA $03
	LDA SlopeDataSize-1,y
	AND #$00FF
	STA $04
	LDA ($01)
	TAY
	LDA ($01),y
	STA !ObjScratch
	LDY $03
	LDX #$02
.Loop
	LDA ($01),y
	STA !ObjScratch,x
	INY #2
	INX #2
	DEC $04
	BNE .Loop
	ASL $00
	LDY $00
	LDA SlopeTypePointers,y
	DEC
	PHA
	SEP #$30
	%CustObjInitStd()
	RTS
	
; $45 = number of tiles to draw on the current line
; $47 = number of tiles drawn on the current line
SlopeSteepL:
	STZ $45
.LoopTop
	STZ $47
	LDA $08
	BEQ .NoShift
	%CustObjShiftRight()
.NoShift
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0002
	CMP #$0025
	BEQ $03
	LDX #$0006
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA $47
	CMP $45
	BEQ .TopNextLine
	INC $47
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch+$04
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA $47
	CMP $45
	BEQ .TopNextLine
	INC $47
.SubLoopTop
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA $47
	CMP $45
	BCS .TopNextLine
	INC $47
	BRA .SubLoopTop
.TopNextLine
	DEC $08
	BMI .EndTop
	LDA #$0001
	%CustObjShiftRight()
	LDA #$0001
	%CustObjShiftDown()
	INC $45
	BRA .LoopTop
.EndTop
	LDA #$0001
	%CustObjShiftRight()
	LDA #$0001
	%CustObjShiftDown()
	LDA !ObjScratch+$04
.LoopBottom
	LDX $04
	STX $08
.SubLoopBottom
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopBottom
	LDA #$0001
	%CustObjShiftDown()
	LDA !ObjScratch
	DEC $0A
	BPL .LoopBottom
	SEP #$30
	RTS

SlopeSteepR:
	STZ $45
.LoopTop
	STZ $47
.SubLoopTop
	LDA $47
	INC
	CMP $45
	BCS .ContinueTop
	LDA !ObjScratch
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	INC $47
	BRA .SubLoopTop
.ContinueTop
	BNE .SkipCorner
	LDA !ObjScratch+$04
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
.SkipCorner
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0002
	CMP #$0025
	BEQ $03
	LDX #$0006
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
.TopNextLine
	DEC $08
	BMI .EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $45
	%CustObjShiftLeft()
	INC $45
	BRA .LoopTop
.EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA !ObjScratch+$04
.LoopBottom
	LDX $04
	STX $08
.SubLoopBottom
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftLeft()
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopBottom
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	%CustObjShiftRight()
	LDA !ObjScratch
	DEC $0A
	BPL .LoopBottom
	SEP #$30
	RTS

SlopeNormalL:
	STZ $45
.LoopTop
	STZ $47
	LDA $08
	BEQ .NoShift
	ASL
	%CustObjShiftRight()
.NoShift
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0002
	CMP #$0025
	BEQ $03
	LDX #$000A
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0004
	CMP #$0025
	BEQ $03
	LDX #$000C
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA $47
	CMP $45
	BEQ .TopNextLine
	INC $47
	LDA !ObjScratch+$06
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch+$08
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA $47
	CMP $45
	BEQ .TopNextLine
	INC $47
.SubLoopTop
	LDA !ObjScratch
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftRight()
	PLA
	SEP #$20
	STA !map16_high,y
	XBA
	STA !map16_low,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA $47
	CMP $45
	BCS .TopNextLine
	INC $47
	BRA .SubLoopTop
.TopNextLine
	DEC $08
	BMI .EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL
	%CustObjShiftLeft()
	INC $45
	JMP .LoopTop
.EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL
	%CustObjShiftLeft()
	LDA !ObjScratch+$06
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch+$08
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA $04
	STA $08
	BRA .SubLoopBottomEntry1
.LoopBottom
	LDX $04
	STX $08
.SubLoopBottom
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftRight()
	PLA
	SEP #$20
	STA !map16_high,y
	XBA
	STA !map16_low,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
.SubLoopBottomEntry1
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopBottom
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL
	%CustObjShiftLeft()
	LDA !ObjScratch
	DEC $0A
	BPL .LoopBottom
	SEP #$30
	RTS

SlopeNormalR:
	STZ $45
.LoopTop
	STZ $47
.SubLoopTop
	LDA $47
	INC
	CMP $45
	BCS .ContinueTop
	LDA !ObjScratch
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftRight()
	PLA
	SEP #$20
	STA !map16_high,y
	XBA
	STA !map16_low,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	INC $47
	BRA .SubLoopTop
.ContinueTop
	BNE .SkipCorner
	LDA !ObjScratch+$06
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch+$08
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
.SkipCorner
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0002
	CMP #$0025
	BEQ $03
	LDX #$000A
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0004
	CMP #$0025
	BEQ $03
	LDX #$000C
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
.TopNextLine
	DEC $08
	BMI .EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $45
	INC
	ASL
	%CustObjShiftLeft()
	INC $45
	JMP .LoopTop
.EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA #$0001
	%CustObjShiftLeft()
	LDA !ObjScratch+$08
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftLeft()
	LDA !ObjScratch+$06
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftLeft()
	LDA $04
	STA $08
	BRA .SubLoopBottomEntry1
.LoopBottom
	LDX $04
	STX $08
.SubLoopBottom
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftLeft()
	PLA
	SEP #$20
	STA !map16_high,y
	XBA
	STA !map16_low,y
	REP #$20
	LDA #$0001
	%CustObjShiftLeft()
.SubLoopBottomEntry1
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopBottom
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL
	%CustObjShiftRight()
	LDA !ObjScratch
	DEC $0A
	BPL .LoopBottom
	SEP #$30
	RTS

SlopeGradualL:
	STZ $45
.LoopTop
	STZ $47
	LDA $08
	BEQ .NoShift
	ASL #2
	%CustObjShiftRight()
.NoShift
	LDX #$0002
.Loop1
	PHX
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	CMP #$0025
	BEQ .NoFill
	TXA
	CLC
	ADC #$0010
	TAX
.NoFill
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	PLX
	INX #2
	CPX #$000A
	BCC .Loop1
	LDA $47
	CMP $45
	BNE .Continue
	JMP .TopNextLine
.Continue
	INC $47
	LDX #$000A
.Loop2
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	INX #2
	CPX #$0012
	BCC .Loop2
	LDA $47
	CMP $45
	BEQ .TopNextLine
	INC $47
.SubLoopTop
	LDX #$0000
	LDA !ObjScratch
.Loop3
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftRight()
	PLA
	XBA
	INX
	CPX #$0004
	BCC .Loop3
	LDA $47
	CMP $45
	BCS .TopNextLine
	INC $47
	BRA .SubLoopTop
.TopNextLine
	DEC $08
	BMI .EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL #2
	%CustObjShiftLeft()
	INC $45
	JMP .LoopTop
.EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL #2
	%CustObjShiftLeft()
	LDX #$000A
.Loop4
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	INX #2
	CPX #$0012
	BCC .Loop4
	LDA $04
	STA $08
	BRA .SubLoopBottomEntry1
.LoopBottom
	LDX $04
	STX $08
.SubLoopBottom
	LDX #$0000
.Loop5
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftRight()
	PLA
	XBA
	INX #2
	CPX #$0008
	BCC .Loop5
.SubLoopBottomEntry1
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopBottom
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL #2
	%CustObjShiftLeft()
	LDA !ObjScratch
	DEC $0A
	BPL .LoopBottom
	SEP #$30
	RTS

SlopeGradualR:
	STZ $45
.LoopTop
	STZ $47
.SubLoopTop
	LDA $47
	INC
	CMP $45
	BCS .ContinueTop
	LDX #$0000
	LDA !ObjScratch
.Loop1
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	XBA
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftRight()
	PLA
	INX #2
	CPX #$0008
	BCC .Loop1
	INC $47
	BRA .SubLoopTop
.ContinueTop
	BNE .SkipCorner
	LDX #$000A
.Loop2
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	INX #2
	CPX #$0012
	BCC .Loop2
.SkipCorner
	LDX #$0002
.Loop3
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	PHX
	CMP #$0025
	BEQ .NoFill
	TXA
	CLC
	ADC #$0010
	TAX
.NoFill
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	PLX
	INX #2
	CPX #$000A
	BCC .Loop3
.TopNextLine
	DEC $08
	BMI .EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $45
	INC
	ASL #2
	%CustObjShiftLeft()
	INC $45
	JMP .LoopTop
.EndTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDX #$0010
.Loop4
	LDA #$0001
	%CustObjShiftLeft()
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	DEX #2
	CPX #$000A
	BCS .Loop4
	LDA $04
	STA $08
	BRA .SubLoopBottomEntry1
.LoopBottom
	LDX $04
	STX $08
.SubLoopBottom
	LDX #$0000
.Loop5
	PHA
	LDA #$0001
	%CustObjShiftLeft()
	PLA
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	XBA
	INX #2
	CPX #$0008
	BCC .Loop5
.SubLoopBottomEntry1
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopBottom
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL #2
	%CustObjShiftRight()
	LDA !ObjScratch
	DEC $0A
	BPL .LoopBottom
	SEP #$30
	RTS

SlopeUpsideDownSteepL:
	LDA !ObjScratch
	PEI ($08)
.LoopTop
	LDX $04
	STX $08
.SubLoopTop
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopTop
	LDA #$0001
	%CustObjShiftDown()
	LDA !ObjScratch
	DEC $0A
	BPL .LoopTop
	PLA
	STA $08
	LDA #$0001
	%CustObjShiftUpAlt()
	LDA !ObjScratch+$02
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	STA $45
	STZ $08
.LoopBottom
	STZ $47
	LDA $08
	BEQ .NoShift
	%CustObjShiftRight()
.NoShift
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0004
	CMP #$0025
	BEQ $03
	LDX #$0008
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA $47
	CMP $45
	BEQ .BottomNextLine
	INC $47
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch+$02
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA $47
	CMP $45
	BEQ .BottomNextLine
	INC $47
.SubLoopBottom
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA $47
	CMP $45
	BCS .BottomNextLine
	INC $47
	BRA .SubLoopBottom
.BottomNextLine
	INC $08
	LDA $08
	DEC
	CMP $04
	BEQ .EndBottom
	LDA #$0001
	%CustObjShiftRight()
	LDA #$0001
	%CustObjShiftDown()
	DEC $45
	JMP .LoopBottom
.EndBottom
	RTS

SlopeUpsideDownSteepR:
	LDA !ObjScratch
.LoopTop
	LDX $04
	STX $08
.SubLoopTop
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopTop
	DEC $0A
	BMI .Break
	LDA #$0001
	%CustObjShiftDown()
	LDA !ObjScratch
	BRA .LoopTop
.Break
	LDA #$0001
	%CustObjShiftLeft()
	LDA !ObjScratch+$02
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA #$0001
	%CustObjShiftDown()
	LDA $04
	STA $45
	STA $08
.LoopBottom
	STZ $47
.SubLoopBottom
	LDA $47
	INC
	CMP $45
	BCS .ContinueBottom
	LDA !ObjScratch
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	INC $47
	BRA .SubLoopBottom
.ContinueBottom
	BNE .SkipCorner
	LDA !ObjScratch+$02
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
.SkipCorner
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0004
	CMP #$0025
	BEQ $03
	LDX #$0006
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
.BottomNextLine
	DEC $08
	BMI .EndBottom
	DEC $04
	LDA #$0001
	%CustObjShiftDown()
	DEC $45
	BRA .LoopBottom
.EndBottom
	RTS

SlopeUpsideDownNormalL:
	LDA !ObjScratch
	PEI ($08)
.LoopTop
	LDX $04
	STX $08
.SubLoopTop
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftRight()
	PLA
	SEP #$20
	STA !map16_high,y
	XBA
	STA !map16_low,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopTop
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL
	%CustObjShiftLeft()
	LDA !ObjScratch
	DEC $0A
	BPL .LoopTop
	PLA
	STA $08
	LDA #$0001
	%CustObjShiftUpAlt()
	LDA !ObjScratch+$02
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch+$04
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA #$0001
	%CustObjShiftLeft()
	LDA $04
	STA $45
	STZ $08
.LoopBottom
	STZ $47
	LDA $08
	BEQ .NoShift
	ASL
	%CustObjShiftRight()
.NoShift
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0006
	CMP #$0025
	BEQ $03
	LDX #$000A
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0008
	CMP #$0025
	BEQ $03
	LDX #$000C
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA $47
	CMP $45
	BEQ .BottomNextLine
	INC $47
	LDA !ObjScratch+$02
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch+$04
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA $47
	CMP $45
	BEQ .BottomNextLine
	INC $47
.SubLoopBottom
	LDA !ObjScratch
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftRight()
	PLA
	SEP #$20
	STA !map16_high,y
	XBA
	STA !map16_low,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA $47
	CMP $45
	BCS .BottomNextLine
	INC $47
	BRA .SubLoopBottom
.BottomNextLine
	INC $08
	LDA $08
	DEC
	CMP $04
	BEQ .EndBottom
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	ASL
	%CustObjShiftLeft()
	DEC $45
	JMP .LoopBottom
.EndBottom
	RTS

SlopeUpsideDownNormalR:
	LDA !ObjScratch
	PEI ($08)
.LoopTop
	LDX $04
	STX $08
.SubLoopTop
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	PHA
	LDA #$0001
	%CustObjShiftRight()
	PLA
	SEP #$20
	STA !map16_high,y
	XBA
	STA !map16_low,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch
	DEC $08
	BPL .SubLoopTop
	LDA #$0001
	%CustObjShiftDownAlt()
	DEC $0A
	BMI .Break
	LDA $04
	INC
	ASL
	%CustObjShiftLeft()
	LDA !ObjScratch
	BRA .LoopTop
.Break
	PLA
	STA $08
	LDA #$0001
	%CustObjShiftUpAlt()
	LDA #$0002
	%CustObjShiftLeft()
	LDA !ObjScratch+$02
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch+$04
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	ASL
	INC
	%CustObjShiftLeft()
	LDA $04
	STA $45
	STA $08
.LoopBottom
	STZ $47
.SubLoopBottom
	LDA $47
	INC
	CMP $45
	BCS .ContinueBottom
	LDA !ObjScratch
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	INC $47
	BRA .SubLoopBottom
.ContinueBottom
	BNE .SkipCorner
	LDA !ObjScratch+$02
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	LDA !ObjScratch+$04
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
.SkipCorner
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0006
	CMP #$0025
	BEQ $03
	LDX #$000A
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
	SEP #$20
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	LDX #$0008
	CMP #$0025
	BEQ $03
	LDX #$000C
	LDA !ObjScratch,x
	SEP #$20
	STA !map16_low,y
	XBA
	STA !map16_high,y
	REP #$20
	LDA #$0001
	%CustObjShiftRight()
.BottomNextLine
	DEC $08
	BMI .EndBottom
	DEC $04
	LDA #$0001
	%CustObjShiftDownAlt()
	LDA $04
	INC
	INC
	ASL
	%CustObjShiftLeft()
	DEC $45
	JMP .LoopBottom
.EndBottom
	RTS
