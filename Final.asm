	.MACRO LOAD_CONST
		LDI @1,LOW(@2)
		LDI @0,HIGH(@2)
	.ENDMACRO 

	.MACRO SET_DIGIT
		PUSH R16
		LDI R16, (0x02<<@0)
		OUT Digits_P, R16
		MOV R16, Dig@0
		RCALL DigitTo7segCode
		OUT Segments_P, R16
		RCALL DelayInMs
		POP R16
	.ENDMACRO

.cseg 
.org 0 rjmp _main
.org 4 rjmp _timer_isr
.org 11 rjmp _generator_isr

_generator_isr:
	ADD PulseEdgeCtrL, R4
	ADC PulseEdgeCtrH, R3
	CLC

reti

_timer_isr:
	RCALL NumberToDigits

	CLR PulseEdgeCtrL
	CLR PulseEdgeCtrH
reti

	.EQU Digits_P = PORTB 
	.EQU Segments_P = PORTD 

	.DEF XL = R16 ; divident
	.DEF XH = R17

	.DEF YL = R18 ; divider 
	.DEF YH = R19

	.DEF RL = R16 ; reminder
	.DEF RH = R17
	
	.DEF QL = R18 ; quotient
	.DEF QH = R19

	.DEF QCtrL = R26
	.DEF QCtrH = R27
	
	.DEF Dig0 = R22
	.DEF Dig1 = R23
	.DEF Dig2 = R24
	.DEF Dig3 = R25
	
	.DEF PulseEdgeCtrL = R0
	.DEF PulseEdgeCtrH = R1

_main:	

	LDI R19, 127
	LDI R20, 31
	OUT DDRD, R19
	OUT DDRB, R20

	LDI R16, (1<<7)
	OUT SREG,  R16

	LDI R16, 0b1100
	OUT TCCR1B , R16

	LDI R16, HIGH(31250)
	LDI R17, LOW(31250)
	OUT OCR1AH ,R16
	OUT OCR1AL, R17

	LDI R16, (1<<6)
	OUT TIMSK , R16
	CLR R16

	LDI R16, (1<<6)
	OUT GIMSK, R16

	LDI R16, (1<<0)
	OUT PCMSK, R16

	LDI R30, Low(Table<<1) 
	LDI R31, High(Table<<1)

	LDI R20, 1
	MOV R4, R20
	CLR R3
Main:
	SET_DIGIT 3
	SET_DIGIT 2
	SET_DIGIT 1
	SET_DIGIT 0

RJMP Main

NumberToDigits:
	LOAD_CONST YH, YL, 1000
	RCALL Divide
	MOV Dig0, QL
	LOAD_CONST YH, YL, 100
	RCALL Divide
	MOV Dig1, QL
	LOAD_CONST YH, YL, 10
	RCALL Divide
	MOV Dig2, QL
	MOV Dig3, RL	
RET

DigitTo7segCode:
	PUSH R18
	MOV R18,R16
	ADD R30,R16
	LPM R16, Z
	SUB R30,R18
	POP R18
RET

Divide:
		CP XL, YL
		CPC XH, YH
		BRLO Reminder
		SUB RL, QL
		SBC RH, QH
		PUSH RL
		LDI RL,1
		ADD QCtrL,RL
		CLR RL
		ADC QCtrH, RL
		POP RL
RJMP Divide

Reminder:
		MOV QL, QCtrL
		MOV QH, QCtrH
		LDI QCtrL,0
		LDI QCtrH,0
RET

DelayInMs:;zwykła etykieta
	PUSH R16
	LDI R16, 5
	LoopM:
		RCALL DelayOneMs
		DEC R16
		BRNE LoopM
		POP R16
RET ;powrót do miejsca wywołania

DelayOneMs:;zwykła etykieta
	PUSH R16
	PUSH R17
	LDI R17, 11
	LDI R16, 99
	Loop: 
		DEC  R16
		BRNE Loop
		DEC  R17
		BRNE Loop
		POP R17
		POP R16
RET ;powrót do miejsca wywołania

Table: .db 0x3F, 0x6, 0x5b, 0x4F, 0x66, 0x6D, 0x7D, 0x7, 0x7F, 0x6F