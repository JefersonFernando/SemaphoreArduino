; Projeto de semáforo com Arduino utilizando chaveamento de LEDs.
;
; Created: 26/06/2022
; Author : Itallo Patrick
; Author : Jeferson Fernando
; Author : João Victor Holanda
; Author : Lucas Buarque 
;
;Clock speed 16 MHz

.cseg
#define RED_LED_BIT 2
#define YELLOW_LED_BIT 1
#define GREEN_LED_BIT 0

#define MAX_STATE 7

#define CLOCK 16.0e6 ;clock speed
#define TIMER_1_DELAY 1.0e-3 ;seconds
#define TIMER_2_DELAY  4.0e-3

.def temp = r16
.def tpointer = r17 ;current LED value
.def current_state = r18
.def remaining_state_time = r19
.def current_showing = r20

jmp reset

.org OC2Aaddr
jmp OCI2A_Interrupt
.org OC1Aaddr
jmp OCI1A_Interrupt

OCI2A_Interrupt:
	push r16
	in r16, SREG
	push r16
	
	pop r16
	out SREG, r16
	pop r16
	reti

OCI1A_Interrupt:
	push r16
	in r16, SREG
	push r16

	dec remaining_state_time

	tst remaining_state_time
	brne return_int1 
	
	inc current_state
	cpi current_state, MAX_STATE
	brne update_state_time

	ldi current_state, 0
	ldi ZH, high(STATE_TIME*2)
	ldi	ZL, low(STATE_TIME*2)

	update_state_time:
	lpm remaining_state_time, Z+

	return_int1:
		pop r16
		out SREG, r16
		pop r16
		reti

STATE_TIME:
.db 26, 4, 56, 4, 11, 4, 20

SEMAPHORE_ONE_STATE:
.db 0b001, 0b001, 0b001, 0b010, 0b100, 0b100, 0b100

SEMAPHORE_TWO_STATE:
.db 0b001, 0b010, 0b100, 0b100, 0b100, 0b100, 0b100

SEMAPHORE_THREE_STATE:
.db 0b100, 0b100, 0b001, 0b010, 0b100, 0b100, 0b100

SEMAPHORE_FOUR_STATE:
.db 0b100, 0b100, 0b100, 0b100, 0b001, 0b010, 0b100

SEMAPHORE_PEDESTRIAN_STATE:
.db 0b100, 0b100, 0b100, 0b100, 0b100, 0b100, 0b001

reset:
	;Stack initialization
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	ldi current_state, 0
	ldi ZH, high(STATE_TIME*2)
	ldi	ZL, low(STATE_TIME*2)
	lpm remaining_state_time, Z+


	.equ WGM = 0b0100 ;Waveform generation mode: CTC
	.equ PRESCALE = 0b100 ;/256 prescale
	.equ PRESCALE_DIV = 256
	
	;you must ensure this value is between 0 and 65535
	.equ TOP = int(0.5 + ((CLOCK/PRESCALE_DIV)*TIMER_1_DELAY))
	.if TOP > 65535
	.error "TOP is out of range"
	.endif

	.equ TOP_TWO = int(0.5 + ((CLOCK/PRESCALE_DIV)*TIMER_2_DELAY))
	.if TOP_TWO > 65535
	.error "TOP is out of range"
	.endif

	///// TOP UM /////
	ldi temp, high(TOP) ;initialize compare value (TOP)
	sts OCR1AH, temp
	ldi temp, low(TOP)
	sts OCR1AL, temp

	ldi temp, ((WGM&0b11) << WGM10) ;lower 2 bits of WGM
	; WGM&0b11 = 0b0100 & 0b0011 = 0b0000 
	sts TCCR1A, temp
	;upper 2 bits of WGM and clock select
	ldi temp, ((WGM>> 2) << WGM12)|(PRESCALE << CS10)
	sts TCCR1B, temp

	lds r16, TIMSK1
	sbr r16, 1 <<OCIE1A
	sts TIMSK1, r16

	///// TOP DOIS /////
	ldi temp, TOP_TWO ;initialize compare value (TOP)
	sts OCR2A, temp

	;ldi temp, ((WGM&0b11) << WGM10) ;lower 2 bits of WGM
	ldi temp, 0b00000010
	; WGM&0b11 = 0b0100 & 0b0011 = 0b0000 
	sts TCCR2A, temp

	ldi temp, 0b00000110
	; WGM&0b11 = 0b0100 & 0b0011 = 0b0000 
	sts TCCR2B, temp

	lds r16, TIMSK2
	sbr r16, 1 <<OCIE2A
	sts TIMSK2, r16

	sei
	main_lp:
			rjmp main_lp