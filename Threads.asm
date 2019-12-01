.MACRO LOAD_CONST  
 ldi  @0,low(@2)
 ldi  @1,high(@2)
.ENDMACRO

.equ DigitsPort = PORTB
.equ SegmentsPort = PORTD
.def CurrentThread=R17
.def ThreadA_LSB = R18
.def ThreadA_MSB = R19
.def ThreadB_LSB = R20
.def ThreadB_MSB = R21
.def Sreg_A = R1
.def Sreg_B = R2
.def Sreg_Glob = R3

.cseg
.org	 0      rjmp	_main
.org 4	rjmp  _Timer_ISR

_Timer_ISR:
	IN Sreg_Glob, SREG
	PUSH R16
	LDI R16,1
	CP CurrentThread, R16
	POP R16
	BREQ Case_B
Case_A:
	MOV Sreg_A, Sreg_Glob
	LDI R16, 0x01
	EOR CurrentThread, R16
	OUT SREG, Sreg_B
		
	POP R16
	MOV ThreadA_MSB, R16
	POP R16
	MOV ThreadA_LSB, R16
	PUSH ThreadB_LSB
	PUSH ThreadB_MSB
	RJMP Stop_Interrupt
Case_B:
	MOV Sreg_B, Sreg_Glob
	LDI R16, 0x01
	EOR CurrentThread, R16
	OUT SREG, Sreg_A

	POP R16
	MOV ThreadB_MSB, R16
	POP R16
	MOV ThreadB_LSB, R16
	PUSH ThreadA_LSB
	PUSH ThreadA_MSB
Stop_Interrupt:
	NOP
  reti

_main: 
	LDI ThreadA_LSB, LOW(ThreadA)
	LDI ThreadA_MSB, HIGH(ThreadA)
	LDI ThreadB_LSB, LOW(ThreadB)
	LDI ThreadB_MSB, HIGH(ThreadB)
	CLR CurrentThread
    ; *** Initialisations ***
	;--- Timer1 --- CTC with 1 prescaller
	LDI R16, (1<<WGM12)|(1<<CS10)
	OUT TCCR1B, R16

	LDI R16, HIGH(100)
	OUT OCR1AH, R16

	LDI R16, LOW(100)
	OUT OCR1AL, R16

	LDI R16, 1<<OCIE1A
	OUT TIMSK, R16
	; --- enable global interrupts
	SEI
	;---  Display  --- 
	LDI R16, 0x06
	OUT DDRB, R16
	LDI R16, 0xFF
	OUT DDRD, R16
	LDI R16, 0x3f
	OUT SegmentsPort, R16

ThreadA:
	IN R22, DigitsPort
	LDI R23, 0b010
	EOR R22, R23
	OUT DigitsPort, R22

	LDI R26, 6
	Loop_A:	
		LOAD_CONST R28,R29,32000
		L_A:			
			SBIW R29:R28,1 
			BRNE L_A
			CLZ
			DEC R26
			cpi r26,0
	BRNE Loop_A
RJMP ThreadA

ThreadB:
	IN R22, DigitsPort
	LDI R23, 0b100
	EOR R22, R23
	OUT DigitsPort, R22

	LDI R27, 4
	Loop_B:
		LOAD_CONST R28,R29,32000
		L_B:
			SBIW R31:R30,1
			BRNE L_B
			CLZ
			DEC R27
			cpi r27,0
	BRNE Loop_B
RJMP ThreadB