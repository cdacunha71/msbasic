.segment "CODE"
;SPREG=$400
;SYREG=$401
;SXREG=$402
;SAREG=$403

SYS:
                jsr FRMNUM              ; Eval formula
                jsr GETADR              ; Convert to int. addr
                lda #>SYSRETURN         ; Push return address
                pha
                lda #<SYSRETURN
                pha
                lda SPREG               ; Status reg
                pha
                lda SAREG               ; Load 6502 regs
                ldx SXREG
                ldy SYREG
                plp                     ; Load 6502 status reg
                jmp (LINNUM)            ; Go do it
SYSRETURN=*-1                
                php                     ; Save status reg
                sta SAREG               ; Save 6502 regs
                stx SXREG
                sty SYREG
                pla                     ; Get status reg
                sta SPREG
                rts

