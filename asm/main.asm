incsrc "defines.asm"

org $0DA106|!bank					; x6A306 (hijack extended object loading routine)
	autoclean JML NewExObjects		; E2 30 A5 59       

org $0DA415|!bank					; x6A615 (hijack normal object loading routine)
	autoclean JML NewNormObjectsJML	; E2 30 AD 31 19
	NOP								; This jumps to another freecode block, in case routines end up being in another bank...
									; not sure if it's necessary, but just to be safe, i guess.

freecode
	db "Objectool v.0100"
;	    0123456789ABCDEF
	dl parameterWords
	dl parameterWordsEx

NewExObjects:
	SEP #$30				; restore hijacked code
	LDA $59					; and load extended object number (was done in the original code anyway)
	CMP #$98				; if the extended object number is equal to or greater than 98...
	BCS CustExObjRt			; then it is a custom extended object
	JML $0DA10A|!bank		;
CustExObjRt:				;
	PHB						;
	PHK						;
	PLB						; change the data bank
	SEC						;
	SBC #$98				;
	ASL						; (no need for 16-bit mode because A can never be greater than #$D0 here)
	TAX						;
	LSR						; keep the extended object number in A (in case it needs to be checked)
	SEC						; set carry to indicate object is extended
	JSR (ExtendedObjPtrs,x)	;
	PLB						;
	JML $0DA53C|!bank		; jump to an RTS in bank 0D

NewNormObjects:
	SEP #$30				;
	LDA $5A					; check the object number
	CMP #$2D				; if it is equal to 2D...
	BEQ CustNormObjRt		; then it is a custom normal object
NotCustomN:					;
	LDA $1931|!addr			; hijacked code
	JML $0DA41A|!bank		;
CustNormObjRt:				;
	LDY #$00				; start Y at 00
	LDA [$65],y				; this should point to the next byte
	STA $5A					; the first new settings byte is the new object number
	INY						; increment Y to get to the next byte
	LDA [$65],y				;
	STA $58					; the second new settings byte
	INY						; increment Y again...
	TYA						;
	CLC						;
	ADC $65					; add 2 to $65 so that the pointer is in the right place,
	STA $65					; since this is a 5-byte object (and SMW's code expects them to be 3 bytes)
	LDA $66					; if the last byte overflowed...
	ADC #$00				; add 1 to it
	STA $66					;
	PHB						;
	PHK						;
	PLB						; change the data bank
	LDA $5A					;
	REP #$30				;
	AND #$00FF				;
	ASL						;
	TAX						;
	LDA NormalObjPtrs,x		; the system needs to be different for these since numbers 00-FF are
	STA $00					; used, making the index go up to #$01FE
	SEP #$30				;
	LDA $5A					; keep the extended object number in A (in case it needs to be checked)
	LDX #$00				;
	CLC						; clear carry to indicate object is not extended
	JSR ($0000|!dp,x)		;
	PLB						;
	JML $0DA53C|!bank		; jump to an RTS in bank 0D

NormalObjPtrs:
	incsrc "work/generatedPointers.asm"	
ExtendedObjPtrs:
	incsrc "work/generatedExPointers.asm"
global #parameterWords:
	incsrc "work/generatedParameters.asm"
global #parameterWordsEx:
	incsrc "work/generatedExParameters.asm"
	incsrc "work/generatedRoutineMacros.asm"
namespace nested off
	incsrc "work/generatedNamespaces.asm"
	
freecode
NewNormObjectsJML:
	JML NewNormObjects
	incsrc "work/generatedRoutines.asm"