.segment "CODE"
.ifdef EATER
PORTB = $8800
PORTA = $8801
DDRB = $8802
DDRA = $8803

.ifdef BITMODE4
E  = %01000000
RW = %00100000
RS = %00010000
.else
E  = %10000000
RW = %01000000
RS = %00100000
.endif

.ifdef BITMODE4
lcd_wait:
  pha
  lda #%11110000  ; LCD data is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcdbusy

  lda #RW
  sta PORTB
  lda #%11111111  ; LCD data is output
  sta DDRB
  pla
  rts
.else
lcd_wait:
  pha
  lda #%00000000  ; LCD data is input
  sta DDRB
lcdbusy:
  lda #RW        ; Set RW bit
  sta PORTA
  lda #(RW|E)    ; Set E bit to send instruction
  sta PORTA      ;
  lda PORTB      ; Read data from PORTB
  and #%10000000 ; Check for MSB set
  bne lcdbusy
  lda #$0
  sta PORTA
  lda #%11111111 ; Set PORTB to output
  sta DDRB
  pla
  rts
.endif

.ifdef BITMODE4
LCDINIT:
  lda #$ff ; Set all pins on port B to output
  sta DDRB

  lda #%00000011 ; Set 8-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB

  lda #%00000011 ; Set 8-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB

  lda #%00000011 ; Set 8-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB

  ; Okay, now we're really in 8-bit mode.
  ; Command to get to 4-bit mode ought to work now
  lda #%00000010 ; Set 4-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB

  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  rts
.else
LCDINIT:
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB

  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000 ; Set to 8 bit operation, 2-line display and 5x8 font
  jsr lcd_instruction

  lda #%00001110 ; Turn on display and cursor
  jsr lcd_instruction

  lda #%00000110 ; Mode to increment, shift cursor to right at write
  jsr lcd_instruction

  lda #%00000001 ; Clear display
  jsr lcd_instruction
  rts
.endif


LCDCMD:
  jsr GETBYT
  txa
.ifdef BITMODE4
lcd_instruction:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  rts
.else
lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #$0        ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #$0        ; Clear RS/RW/E bits
  sta PORTA
  rts
.endif

.ifdef BITMODE4
LCDPRINT:
  jsr GETBYT
  txa
lcd_p:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  pla
  and #%00001111  ; Send low 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  rts
.else

LCDPRINT:
  jsr GETBYT
  txa
lcd_p:
  jsr lcd_wait
  sta PORTB
  lda #RS        ; Set RS, clear RW/E bits
  sta PORTA
  lda #(RS|E)    ; Set E bit to send instruction
  sta PORTA
  lda #RS
  sta PORTA
  rts
.endif

;; Copied from print.s
LCDSTR:
  jsr     FRMEVL
  bit     VALTYP
  bmi     @get_string
  rts
@get_string:
  jsr     FREFAC
  tax
  ldy     #$00
  inx
@print_string:
  dex
  beq     @end_lcdstr
  lda     (INDEX),y
  jsr     lcd_p
  iny
  jmp     @print_string
@end_lcdstr:
  rts


LCDCLS:
  lda #$01
  jsr lcd_instruction
  rts

CLS:
  lda #$0C
  sta ACIA_DATA
  rts
.endif
