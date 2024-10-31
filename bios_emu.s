.setcpu "65C02"
.debuginfo


.zeropage
		.org ZP_START0
READ_PTR:	.res 1
WRITE_PTR:	.res 1

.segment "INPUT_BUFFER"
INPUT_BUFFER:	.res $100

.segment "BIOS"

ACIA_DATA   = $5000
ACIA_STATUS = $5001
ACIA_CMD    = $5002
ACIA_CTRL   = $5003

LOAD:
		rts
SAVE:
		rts
; Input a character from the serial interface
; On return, carry flag indicates whether a key was pressed
; If a key was pressed, the key value will be in the A register
;
; Modifies: flags, A, X
MONRDKEY:
CHRIN:
                lda     ACIA_STATUS
                and     #$08
                beq     @no_keypressed
                lda     ACIA_DATA
                jsr     CHROUT			; echo
                sec
                rts
@no_keypressed:
                clc
                rts

; Output a character (from the A register) to the serial interface.
;
; Modifies: flags
MONCOUT:
CHROUT:
		pha
		sta ACIA_DATA
		lda #$FF
@tx_delay:	
		dec
		bne @tx_delay
		pla
		rts

; Initialize the circular input buffer
; Modifies: flags, A
INIT_BUFFER:
		lda READ_PTR
		sta WRITE_PTR
		rts

; Write a character to the circular buffer (from the A register)
; Modifies: flags, A, X
WRITE_BUFFER:
		ldx WRITE_PTR		; load WRITE_PTR into X
		sta INPUT_BUFFER,x	; store data in buffer using offset X
		inc WRITE_PTR		; increment WRITE_PTR
		rts

; Read a character from the circular buffer and store it in A
; Modifies: flags, A, X
READ_BUFFER:
		ldx READ_PTR		; load READ_PTR into X
		lda INPUT_BUFFER,x	; read data in buffer using offset X
		inc READ_PTR		; increment READ_PTR
		rts


; Return in (A) the number of bytes in the circular input buffer
; Modifies: flags, A
BUFFER_SIZE:
		lda WRITE_PTR
		sec
		sbc READ_PTR
		rts

; Interrupt request handler
IRQ_HANDLER:
		pha
		phx
		lda ACIA_STATUS		; reset IRQ
		lda ACIA_DATA
		jsr WRITE_BUFFER
		jsr BUFFER_SIZE
		cmp #$F0
		bcc @not_full
		lda #$01
		sta ACIA_CMD
@not_full:
		plx
		pla
		rti

.include "wozmon.s"

.segment "RESETVEC"
                .word   $0F00          ; NMI vector
                .word   RESET          ; RESET vector
                .word   IRQ_HANDLER    ; IRQ vector
