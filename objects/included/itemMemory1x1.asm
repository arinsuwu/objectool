;------------------------------------------------
;	Make an object composed of a single Map16 tile that can be set to use item memory
;	To be inserted as a normal object.
;
;	The "single block" object simply creates one specified Map16 tile that can be stretched in both directions
;	and can also be set to check item memory (as coins do to determine if they've already been collected).
;
;	The tile number is set by the table indexed with the object's extra byte.
;
;	Note that actually setting the item memory bit must be done in the code of the blocks that make up the object,
;	so you cannot make an object with this out of a vanilla Map16 tile that doesn't use item memory (such as a throw block) and have it work the intended way. 
;------------------------------------------------

tiles:
	dw $002B

load:
	LDA !obj_settings
	AND #$0F
	STA $00
	STA $02
	LDA !obj_settings
	LSR #4
	STA $01
	LDA !extra_byte
	ASL
	TAY
	LDA tiles,y
	STA $0C
	LDA tiles+1,y
	STA $0D
	LDY !obj_pos
	%BackUpPtrs()
.StartObjLoop0
;	BRA .SetTileNumber	; uncommenting this line will make the object ignore checking item memory
	%GetItemMemoryBit()
	BEQ .SetTileNumber
	%ShiftObjRight()
	BRA .DecAndLoop0
.SetTileNumber
	LDA $0C
	STA !map16_low,y
	LDA $0D
	STA !map16_high,y
	%ShiftObjRight()
.DecAndLoop0
	DEC $00
	BPL .StartObjLoop0
	%RestorePtrs()
	%ShiftObjDown()
	LDA $02
	STA $00
	DEC $01
	BMI .EndObjLoop0
	JMP .StartObjLoop0
.EndObjLoop0
	RTS