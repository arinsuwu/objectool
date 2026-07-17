include

; Macro for calling SNES CPU. Label should point to a routine which ends in RTL.
; Data bank is not set, so use PHB/PHK/PLB ... PLB in your SNES code.
macro invoke_snes(addr)
    LDA.b #<addr>
    STA $0183
    LDA.b #<addr>/256
    STA $0184
    LDA.b #<addr>/65536
    STA $0185
    LDA #$D0
    STA $2209
-   LDA $018A
    BEQ -
    STZ $018A
endmacro

; Same as invoke_snes except for SA-1, object code runs at SA-1 already, so you'll likely never need to use this.
macro invoke_sa1(label)
    LDA.b #<label>
    STA $3180
    LDA.b #<label>>>8
    STA $3181
    LDA.b #<label>>>16
    STA $3182
    JSR $1E80
endmacro

