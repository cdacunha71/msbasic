ISCNTC:
	jsr MONRDKEY
	bcc not_cntc
	cmp #$03
	bne not_cntc
	jmp is_cntc
not_cntc:
	rts
is_cntc:
	; fall through
