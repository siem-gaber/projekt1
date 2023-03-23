
.EQU led1 = PORTB0
.EQU led2 = PORTB1
.EQU button1 = PORTB4
.EQU button2 = PORTB5
.EQU button3 = PORTB3


.EQU TIMER0_MAX_COUNT = 18
.EQU TIMER1_MAX_COUNT = 6
.EQU TIMER2_MAX_COUNT = 12


.EQU TIMER2_OVF_vect = 0x12
.EQU TIMER1_COMPA_vect = 0x16
.EQU TIMER0_OVF_vect = 0x20
.EQU RESET_vect = 0X00
.EQU PCINT0_vect = 0X06


.DSEG
.ORG SRAM_START
counter0:   .byte 1
counter1:	.byte 1
counter2:	.byte 1
led1_state:	.byte 1
led2_state:	.byte 1

.CSEG

.ORG RESET_vect
RJMP main

.ORG PCINT0_vect
RJMP ISR_PCINT0

.ORG TIMER2_OVF_vect
RJMP ISR_TIMER2_OVF

.ORG TIMER1_COMPA_vect
RJMP ISR_TIMER1_COMPA

.ORG TIMER0_OVF_vect
RJMP ISR_TIMER0_OVF


ISR_PCINT0:
CLR R24
STS PCICR, R24
STS TIMSK0, R16


IN R18, PINB
ANDI R18, (1 << BUTTON1)
BRNE change_state_led1


IN R18, PINB
ANDI R18, (1 << BUTTON2)
BRNE change_state_led2


IN R18, PINB
ANDI R18, (1 << BUTTON3)
BRNE reset


ISR_PCINT0_end:
RETI


reset:

CLR R24
STS TIMSK1, R24
STS TIMSK2, R24


STS led1_state, R24
STS led2_state, R24
IN R24, PORTB
ANDI R24, ~((1 << LED1) | (1 << LED2))
OUT PORTB, R24
RETI


change_state_led1:
LDS R26, led1_state
CPI R26, 1
BREQ change_state_led1_off
change_state_led1_on:
STS TIMSK1, R17
LDI R26, 1
STS led1_state, R26
RETI
change_state_led1_off:
CLR R26
STS led1_state, R26
STS TIMSK1, R26
CALL led1_off
RETI

change_state_led2:
LDS R26, led2_state
CPI R26, 1
BREQ change_state_led2_off
change_state_led2_on:
STS TIMSK2, R16
LDI R26, 1
STS led2_state, R26
RETI
change_state_led2_off:
CLR R26
STS led2_state, R26
STS TIMSK2, R26
CALL led2_off
RETI

led1_off:
IN R24, PORTB
ANDI R24, ~(1 << LED1)
OUT PORTB, R24
RET
led2_off:
IN R24, PORTB
ANDI R24, ~(1 << LED2)
OUT PORTB, R24
RET

ISR_TIMER0_OVF:
LDS R24, counter0
INC R24
CPI R24, TIMER0_MAX_COUNT
BRLO ISR_TIMER0_OVF_end


STS PCICR, R16
CLR R24
STS TIMSK0, R24
ISR_TIMER0_OVF_end:
STS counter0, R24
RETI

ISR_TIMER1_COMPA:
LDS R24, counter1
INC R24
CPI R24, TIMER1_MAX_COUNT
BRLO ISR_TIMER1_COMPA_end

OUT PINB, R16
CLR R24
ISR_TIMER1_COMPA_end:
STS counter1, R24
RETI

ISR_TIMER2_OVF:
LDS R24, counter2
INC R24
CPI R24, TIMER2_MAX_COUNT
BRLO ISR_TIMER2_OVF_end
OUT PINB, R17
CLR R24
ISR_TIMER2_OVF_end:
STS counter2, R24
RETI

main:
setup:
LDI R16, (1 << led1) | (1 << led2)
OUT DDRB, R16
LDI R16, (1 << led1)
LDI R17, (1 << led2)
LDI R18, (1 << button1) | (1 << button2) | (1 << button3)
OUT PORTB, R18

STS PCICR, R16 ; PCICR = (1 << PCIE0);
STS PCMSK0, R18

LDI R24, (1 << CS02) | (1 << CS00)
OUT TCCR0B, R24

LDI R24, (1 << WGM12) | (1 << CS12) | (1 << CS10)
STS TCCR1B, R24
LDI R24, high(256)
STS OCR1AH, R24
LDI R24, low(256)
STS OCR1AL, R24
;STS TIMSK1, R17

LDI R24, (1 << CS22) | (1 << CS21) | (1 << CS20)
STS TCCR2B, R24
;STS TIMSK2, R16

SEI

main_loop:
RJMP main_loop