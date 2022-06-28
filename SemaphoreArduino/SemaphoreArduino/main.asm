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

#define RED_LED_PORT PORTD
#define RED_LED_PIN 0

#define YELLOW_LED_PORT PORTD
#define YELLOW_LED_PIN 1

#define GREEN_LED_PORT PORTD
#define GREEN_LED_PIN 2

#define DISPLAY_ONE_PORT PORTD
#define DISPLAY_ONE_PIN 3

#define DISPLAY_TWO_PORT PORTC
#define DISPLAY_TWO_PIN 4

#define DISPLAY_OUT_PORT PORTD
#define DISPLAY_OUT_PIN 4

#define MAX_STATE 7
#define MAX_SEMAPHORE 5

#define CLOCK 16.0e6 ;clock speed
#define TIMER_1_DELAY 1.0e-3 ;seconds
#define TIMER_2_DELAY  4.0e-3

//Define pino e porta que ativa o semáforo 1.
#define SEMAPHORE_ONE_PORT PORTC
#define SEMAPHORE_ONE_PIN 4

//Define pino e porta que ativa o semáforo 2.
#define SEMAPHORE_TWO_PORT PORTC
#define SEMAPHORE_TWO_PIN 3

//Define pino e porta que ativa o semáforo 3.
#define SEMAPHORE_THREE_PORT PORTC
#define SEMAPHORE_THREE_PIN 2

//Define pino e porta que ativa o semáforo 4.
#define SEMAPHORE_FOUR_PORT PORTC
#define SEMAPHORE_FOUR_PIN 1

//Define pino e porta que ativa o semáforo de pedestres.
#define SEMAPHORE_PEDESTRIAN_PORT PORTC
#define SEMAPHORE_PEDESTRIAN_PIN 0

.def temp = r16
.def temp2 = r17
.def current_state = r18
.def remaining_state_time = r19
.def current_showing = r20
.def current_leds = r21

jmp reset

.org OC2Aaddr
jmp OCI2A_Interrupt
.org OC1Aaddr
jmp OCI1A_Interrupt

OCI2A_Interrupt:
	push r16
	in r16, SREG
	push r16

	// Apaga tudo
	ldi temp, 0
	out PORTC, temp
	out PORTD, temp
	
	// Verifica se o semáforo a ser exibido é o primeiro.
	cpi current_showing, 0
	brne verify_second_semaphore

	ldi temp, 0
	ldi ZH, high(SEMAPHORE_ONE_STATE*2)
	ldi	ZL, low(SEMAPHORE_ONE_STATE*2)
	add ZL, current_state // Adiciona o offset current_state ao ZL
	adc ZH, temp // Se a operação em ZL der overflow, adiciona o carry em ZH

	lpm current_leds, Z // Carrega os bits dos leds do semáforo

	in temp, SEMAPHORE_ONE_PORT
	ori temp, 1 << SEMAPHORE_ONE_PIN
	out SEMAPHORE_ONE_PORT, temp
	
	rjmp skip_semaphore_verify
	// Verifica se o semáforo a ser exibido é o segundo.
	verify_second_semaphore:
		cpi current_showing, 1
		brne verify_third_semaphore

		ldi temp, 0
		ldi ZH, high(SEMAPHORE_TWO_STATE*2)
		ldi	ZL, low(SEMAPHORE_TWO_STATE*2)
		add ZL, current_state
		adc ZH, temp

		lpm current_leds, Z

		in temp, SEMAPHORE_TWO_PORT
		ori temp, 1 << SEMAPHORE_TWO_PIN
		out SEMAPHORE_TWO_PORT, temp

		rjmp skip_semaphore_verify
	// Verifica se o semáforo a ser exibido é o terceiro.
	verify_third_semaphore:
		cpi current_showing, 2
		brne verify_fourth_semaphore

		ldi temp, 0
		ldi ZH, high(SEMAPHORE_THREE_STATE*2)
		ldi	ZL, low(SEMAPHORE_THREE_STATE*2)
		add ZL, current_state
		adc ZH, temp

		lpm current_leds, Z

		rjmp skip_semaphore_verify
	
	// Verifica se o semáforo a ser exibido é o quarto.
	verify_fourth_semaphore:
		cpi current_showing, 3
		brne verify_pedestrian_semaphore

		ldi temp, 0
		ldi ZH, high(SEMAPHORE_THREE_STATE*2)
		ldi	ZL, low(SEMAPHORE_THREE_STATE*2)
		add ZL, current_state
		adc ZH, temp

		lpm current_leds, Z

	in temp, SEMAPHORE_THREE_PORT
	ori temp, 1 << SEMAPHORE_THREE_PIN
	out SEMAPHORE_THREE_PORT, temp

	rjmp skip_semaphore_verify
	// Verifica se o semáforo a ser exibido é o de pedestres.
	verify_pedestrian_semaphore:
	ldi temp, 0
	ldi ZH, high(SEMAPHORE_PEDESTRIAN_STATE*2)
	ldi	ZL, low(SEMAPHORE_PEDESTRIAN_STATE*2)
	add ZL, current_state
	adc ZH, temp

	lpm current_leds, Z

	in temp, SEMAPHORE_PEDESTRIAN_PORT
	ori temp, 1 << SEMAPHORE_PEDESTRIAN_PIN
	out SEMAPHORE_PEDESTRIAN_PORT, temp

	skip_semaphore_verify:

		inc current_showing // Atualiza o semáforo atual
		cpi current_showing, MAX_SEMAPHORE // Verifica se passou do último semáforo
		brne skip_current_showing_zero // Se não passar do último, vai para a label skip_current_showing_zero

		ldi current_showing, 0 // Se passou do último, volta para o primeiro

	skip_current_showing_zero:
		// Início da cor vermelha
		// Atualiza estado do led vermelho.
		mov temp, current_leds
		andi temp, 1 << RED_LED_BIT // Filtra o valor do bit do led vermelho
		tst temp // verifica se o valor do bit do led vermelho é igual a 0
		brne red_led_on // se não for igual a 0, ele é 1 e precisa ser ligado

		in temp, RED_LED_PORT
		andi temp, ~(1 << RED_LED_PIN) 
		out RED_LED_PORT, temp

		rjmp red_led_end // vai para a outra cor do semáforo
	
	red_led_on:
		in temp, RED_LED_PORT // Lê os bits da porta usada
		ori temp, 1 << RED_LED_PIN // Seta 1 no bit específico referente ao pino do led
		out RED_LED_PORT, temp // Salva os bits

	red_led_end:
		// Início do cor amarela
		// Atualiza estado do led amarelo.
		mov temp, current_leds
		andi temp, 1 << YELLOW_LED_BIT // Filtra o valor do bit do led amarelo
		tst temp // verifica se o valor do bit do led amarelo é igual a 0
		brne yellow_led_on // se não for igual a 0, ele é 1 e precisa ser ligado

		in temp, YELLOW_LED_PORT
		andi temp, ~(1 << YELLOW_LED_PIN)
		out YELLOW_LED_PORT, temp

		rjmp yellow_led_end

	yellow_led_on:
		in temp, YELLOW_LED_PORT
		ori temp, 1 << YELLOW_LED_PIN
		out YELLOW_LED_PORT, temp

	yellow_led_end:
		// Início do cor amarela
		// Atualiza estado do led verde.
		mov temp, current_leds
		andi temp, 1 << GREEN_LED_BIT
		tst temp
		brne green_led_on

		in temp, GREEN_LED_PORT
		andi temp, ~(1 << GREEN_LED_PIN)
		out GREEN_LED_PORT, temp

		rjmp green_led_end

	green_led_on:
		in temp, GREEN_LED_PORT
		ori temp, 1 << GREEN_LED_PIN
		out GREEN_LED_PORT, temp

	green_led_end:
		// Chaveia os diplays de 7 segmentos.
		in temp, DISPLAY_ONE_PORT
		andi temp, 1 << DISPLAY_ONE_PIN
		tst temp
		brne display_two_on

		in temp, DISPLAY_ONE_PORT
		ori temp, 1 << DISPLAY_ONE_PIN
		out DISPLAY_ONE_PORT, temp

		mov temp, remaining_state_time

		// Subtrai até ser menor que 10 (primeiro digito).
		mod_10:
		cpi temp, 10
		brlo exit_mod
		subi temp, 10
		rjmp mod_10
	exit_mod:

		rjmp end_display
	display_two_on:

		mov temp2, remaining_state_time

		ldi temp, 0
		div_10:
		cpi temp2, 10
		brlo exit_div
		subi temp2, 10
		inc temp
		rjmp div_10
	exit_div:

	end_display:

		ldi temp2, DISPLAY_OUT_PIN

	shift_bit:

		cpi temp2, 0
		breq exit_shift_bit
		dec temp2
		lsl temp
		rjmp shift_bit
	exit_shift_bit:

		in temp2, DISPLAY_OUT_PORT
		or temp2, temp
		out DISPLAY_OUT_PORT, temp2

		in temp, DISPLAY_TWO_PORT
		ori temp, 1 << DISPLAY_TWO_PIN
		out DISPLAY_TWO_PORT, temp

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

	update_state_time:
		ldi temp, 0
		ldi ZH, high(STATE_TIME*2)
		ldi	ZL, low(STATE_TIME*2)
		add ZL, current_state
		adc ZH, temp

		lpm remaining_state_time, Z

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

	//Configura pinos 0 a 5 do barramento C como saída
	ldi temp, 0b11111
	out DDRC, temp

	//Configura todos os pinos do barramento D como saída
	ldi temp, 0xFF
	out DDRD, temp

	ldi temp, 0
	ldi current_state, 0
	ldi ZH, high(STATE_TIME*2)
	ldi	ZL, low(STATE_TIME*2)
	add ZL, current_state
	adc ZH, temp

	lpm remaining_state_time, Z

	ldi current_showing, 0


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