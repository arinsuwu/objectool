;------------------------------------------------
; Make a ledge or block object, which can be specified to have various edges or not
; This object has 16 variations that depend on the parameter byte's value.
; To be inserted as a custom normal object.
;
;	Extra Byte:
;	tttt PPPP
;
;	Parameter Word:
;	---- ---- ---- TTTT
;
; - Tt is used as an index to the tile data table.
;		Which means that a single ledge object list entry can have up to 16 tables.
;
; - P indicates which corners and edges will be used:
;		0 = top
;		1 = top with left corner
;		2 = top with right corner
;		3 = top with left and right corners
;		4 = bottom
;		5 = bottom with left corner
;		6 = bottom with right corner
;		7 = bottom with left and right corners
;		8 = left edge
;		9 = right edge
;		A = left edge with top and bottom corners
;		B = right edge with top and bottom corners
;		C = top and bottom edges
;		D = left and right edges
;		E = all 4 edges and corners
;		F = 4 inside corners
;
; 9 tiles with air background: top-left corner, ledge, top-right corner, left side, middle, right side, bottom-left corner, ceiling, bottom-right corner
; 8 tiles with filled background: top-left corner, ledge, top-right corner, left side, right side, bottom-left corner, ceiling, bottom-right corner
; 4 inside corner tiles: bottom-left, bottom-right, top-left, top-right
; 2 tiles for when one edge overlaps another edge: left, right
;------------------------------------------------

LedgeTiles:

; Solid
	dw $0200,$0201,$0202
	dw $0210,$0211,$0212
	dw $0220,$0221,$0222
	
	dw $0204,$0201,$0205
	dw $0210,      $0212
	dw $0214,$0221,$0215
	
	dw $0229,$022A
	dw $0219,$021A
	
	dw $0211,$0211

; Semisolid
	dw $0207,$0201,$0208
	dw $0217,$0211,$0218
	dw $0217,$0211,$0218
	
	dw $0209,$0201,$020A
	dw $0217,      $0218
	dw $0217,$0211,$0218
	
	dw $0229,$022A
	dw $0219,$021A
	
	dw $0217,$0218
	
; LedgeTiles2

; Solid
	dw $0145,$0100,$0148
	dw $014B,$003F,$014C
	dw $014D,$014E,$014F
	
	dw $0146,$0100,$0149
	dw $014B,      $014C
	dw $014D,$014E,$014F
	
	dw $01E4,$01E2
	dw $01EC,$01ED
	
	dw $003F,$003F
	
; Semisolid
	dw $0101,$0100,$0103
	dw $0040,$003F,$0041
	dw $0040,$003F,$0041
	
	dw $0102,$0100,$0104
	dw $0040,      $0041
	dw $0040,$003F,$0041
	
	dw $01E4,$01E2
	dw $01EC,$01ED
	
	dw $003F,$003F

load:
	ASL
	TAX
	LDA parameterWords,x
	AND #$0F
	ASL #4
	STA $00
	LDA !extra_byte
	AND #$0F
	TAX
	LDA !extra_byte
	LSR #4
	ORA $00
if !sa1
	STZ $2250
endif
	REP #$30
	STX $45
	AND #$00FF
if !sa1
	STA $2251
	LDA #$002E
	STA $2253
	NOP
	LDX $2306
else
	ORA #$2E00
	STA $4202
	PHA
	PLA
	LDX $4216
endif
	LDA.w LedgeTiles,x
	STA !obj_scratch
	LDA.w LedgeTiles+$02,x
	STA !obj_scratch+$02
	LDA.w LedgeTiles+$04,x
	STA !obj_scratch+$04
	LDA.w LedgeTiles+$06,x
	STA !obj_scratch+$06
	STA !obj_scratch+$2E
	LDA.w LedgeTiles+$08,x
	STA !obj_scratch+$08
	LDA.w LedgeTiles+$0A,x
	STA !obj_scratch+$0A
	STA !obj_scratch+$30
	LDA.w LedgeTiles+$0C,x
	STA !obj_scratch+$0C
	LDA.w LedgeTiles+$0E,x
	STA !obj_scratch+$0E
	LDA.w LedgeTiles+$10,x
	STA !obj_scratch+$10
	LDA.w LedgeTiles+$12,x
	STA !obj_scratch+$12
	LDA.w LedgeTiles+$14,x
	STA !obj_scratch+$14
	LDA.w LedgeTiles+$16,x
	STA !obj_scratch+$16
	LDA.w LedgeTiles+$18,x
	STA !obj_scratch+$18
	LDA.w LedgeTiles+$1A,x
	STA !obj_scratch+$1A
	LDA.w LedgeTiles+$1C,x
	STA !obj_scratch+$1C
	LDA.w LedgeTiles+$1E,x
	STA !obj_scratch+$1E
	LDA.w LedgeTiles+$20,x
	STA !obj_scratch+$20
	LDA.w LedgeTiles+$22,x
	STA !obj_scratch+$22
	LDA.w LedgeTiles+$24,x
	STA !obj_scratch+$24
	LDA.w LedgeTiles+$26,x
	STA !obj_scratch+$26
	LDA.w LedgeTiles+$28,x
	STA !obj_scratch+$28
	LDA.w LedgeTiles+$2A,x
	STA !obj_scratch+$2A
	LDA.w LedgeTiles+$2C,x
	STA !obj_scratch+$2C
	PHY
	LDA $45
	ASL #4
	TAX
	LDY .TileIndexLookup,x
	LDA !obj_scratch,y
	STA !obj_scratch
	TYA
	LSR
	STA !obj_scratch+$40
	LDY .TileIndexLookup+2,x
	LDA !obj_scratch,y
	STA !obj_scratch+$02
	TYA
	LSR
	STA !obj_scratch+$41
	LDY .TileIndexLookup+4,x
	LDA !obj_scratch,y
	STA !obj_scratch+$04
	TYA
	LSR
	STA !obj_scratch+$42
	LDY .TileIndexLookup+6,x
	LDA !obj_scratch,y
	STA !obj_scratch+$06
	TYA
	LSR
	STA !obj_scratch+$43
	LDY .TileIndexLookup+8,x
	LDA !obj_scratch,y
	STA !obj_scratch+$0A
	TYA
	LSR
	STA !obj_scratch+$45
	LDY .TileIndexLookup+10,x
	LDA !obj_scratch,y
	STA !obj_scratch+$0C
	TYA
	LSR
	STA !obj_scratch+$46
	LDY .TileIndexLookup+12,x
	LDA !obj_scratch,y
	STA !obj_scratch+$0E
	TYA
	LSR
	STA !obj_scratch+$47
	LDY .TileIndexLookup+14,x
	LDA !obj_scratch,y
	STA !obj_scratch+$10
	TYA
	LSR
	STA !obj_scratch+$48
	PLY
	SEP #$30
	LDA #$04
	STA !obj_scratch+$44
	%StoreNybbles()
	LDY !obj_pos
	LDA $08
	STA $00
	LDA $09
	STA $01
	%BackUpPtrs()
.StartObjLoop
	LDX #$00
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
	BEQ .NoInc2
	INX
	CMP #$00
	BNE .NoInc2
	INX
.NoInc2
	LDA !obj_scratch+$40,x
	TAX
; if the current tile is the middle or is over top of a blank tile, then use the specified tile number
; if it's over top of the middle fill tile, then use the "filled-in" versions of the tiles
; if it's a corner tile and is over top of a matching edge, change it into an inside corner (or just the filled-in corner for passable ledges)
; if it's an edge tile and is over top of a matching edge, change it into the "overlapping edge" tile (usually identical to either the normal filled-in edge tile for passable edges or the middle tile for solid ones)
	LDA !map16_high,y
	XBA
	LDA !map16_low,y
	REP #$20
	CPX #$04
	BEQ .SetBlockIndex
	CMP #$0025
	BEQ .SetBlockIndex
	CMP !obj_scratch+$08
	BEQ .FilledInTile
	CMP !obj_scratch+$2E
	BEQ .OverlappingEdge
	CMP !obj_scratch+$30
	BEQ .OverlappingEdge
.FilledInTile
	TXA
	CLC
	ADC #$0009
	TAX
	CPX #$0D
	BCC .SetBlockIndex
	DEX
	BRA .SetBlockIndex
.OverlappingEdge
	LDA .OverlapTileType,x
	TAX
.SetBlockIndex
	TXA
	ASL
	TAX
	LDA !obj_scratch,x
	SEP #$20
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

.TileIndexLookup
	dw $0002,$0002,$0002,$0008,$0008,$0008,$0008,$0008
	dw $0000,$0002,$0002,$0006,$0008,$0006,$0008,$0008
	dw $0002,$0002,$0004,$0008,$000A,$0008,$0008,$000A
	dw $0000,$0002,$0004,$0006,$000A,$0006,$0008,$000A
	dw $0008,$0008,$0008,$0008,$0008,$000E,$000E,$000E
	dw $0006,$0008,$0008,$0006,$0008,$000C,$000E,$000E
	dw $0008,$0008,$000A,$0008,$000A,$000E,$000E,$0010
	dw $0006,$0008,$000A,$0006,$000A,$000C,$000E,$0010
	dw $0006,$0008,$0008,$0006,$0008,$0006,$0008,$0008
	dw $0008,$0008,$000A,$0008,$000A,$0008,$0008,$000A
	dw $0000,$0002,$0002,$0006,$0008,$000C,$000E,$000E
	dw $0002,$0002,$0004,$0008,$000A,$000E,$000E,$0010
	dw $0002,$0002,$0002,$0008,$0008,$000E,$000E,$000E
	dw $0006,$0008,$000A,$0006,$000A,$0006,$0008,$000A
	dw $0000,$0002,$0004,$0006,$000A,$000C,$000E,$0010
	dw $0024,$0008,$0022,$0008,$0008,$0028,$0008,$0026

.OverlapTileType
	db $11,$0A,$12,$15,$FF,$16,$13,$0F,$14

