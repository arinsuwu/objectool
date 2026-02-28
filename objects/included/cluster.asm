;------------------------------------------------
;   "cluster" object (i.e., always has the same arrangement of tiles but without a pattern)
;   To be inserted as either a normal or extended object.
;
;	As a custom object: The object's extra byte determines which table it should use.
;	As an extended object: The object's parameter byte determines which table it should use.
;
;	The "cluster" object routine uses three tables: one to specify the dimensions, one for pointers to the tile number table, and one for the actual tile numbers.
;
;	In the size table, the first digit is the Y dimension and the second is the X
;   (and both are 1 less than the actual value, so $03 will create a 1x4 object, as the example shows).
;
;	The pointers specify where the Map16 tile table is, and the Map16 table, of course, specifies which tiles the object will create.
;
;	Specifying a tile number as $FFFF indicates the end of an entry and will make the object repeat the sequence.
;------------------------------------------------

; dimensions of extended objects consisting of a large group of tiles
ClusterExObjSize:
	db $03,$33

; pointers to the tilemaps of extended objects consisting of a large group of tiles
pointers:
	dw .ExampleA
	dw .ExampleB

; map16 tiles
.ExampleA:
	dw $020C,$020D,$020E
	dw $FFFF
.ExampleB:
	dw $016A,$016B,$016C,$016D
	dw $006A,$006B,$006C,$006D
	dw $FFFF
	
load:
	LDY !extra_byte
	LDA !obj_settings
	BCC .NotExtended
.Extended:
	LDA !extended_num
	REP #$30
	AND #$00FF
	ASL
	TAY
	LDA.w parameterWordsEx,y
	TAY
	SEP #$20
	LDA ClusterExObjSize,y
	SEP #$10
.NotExtended:
	PHA
	AND #$0F
	STA $00
	STA $02
	PLA
	LSR #4
	STA $01
	TYA
	ASL
	TAY
	REP #$20
	LDA pointers,y
	STA $0A
	STA !obj_scratch
	SEP #$20
	LDY !obj_pos
	%BackUpPtrs()
.Loop
	REP #$20
	LDA ($0A)
	CMP #$FFFF
	SEP #$20
	BNE +
	LDA !obj_scratch   : STA $0A
	LDA !obj_scratch+1 : STA $0B
	BRA .Loop
+	STA !map16_low,y
	XBA
	STA !map16_high,y
.SkipTile
	%ShiftObjRight()
	REP #$20
	INC $0A
	INC $0A
	SEP #$20
	DEC $00
	BPL .Loop
	%RestorePtrs()
	%ShiftObjDown()
	LDA $02
	STA $00
	DEC $01
	BPL .Loop
	RTS