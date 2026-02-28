;------------------------------------------------
; store object variables to scratch RAM
;
; X position to $06
; Y position to $07
; width to $08
; height to $09
;------------------------------------------------

main:
	LDA $57
	AND #$0F
	STA $06
	LDA $57
	LSR #4
	STA $07
	LDA $59
	AND #$0F
	STA $08
	LDA $59
	LSR #4
	STA $09
	RTL