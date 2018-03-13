;***********************************************************
;*
;*	receive.asm
;*
;*	Receives data from another TekBot
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Fauzi Kliman and Aidan Carson
;*	   Date: 2/27/2018
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	lit = r17				; Register for light
.def	received = r18			; Flag for address recieved
.def	numbFrozen = r22		; Number of times bot froxen
.def	whiskyState	= r23		; State of the whiskys
.def	speed = r24

.def	waitcnt = r19			; Register for wait time
.def	ilcnt = r20				; Inner loop register for wait function
.def	olcnt = r21				; Outer loop register for wait function

.equ	WTime = 100;			; Wait time for moving
.equ	SpeedIncTime = 50		; Wait time for inc/dec pwm speed

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = $2A;(Enter your robot's address here (8 bits))

.equ	InitClkVal = 3036		; Initial value of LCD clk for timer 1
.equ	LWhiskyState = 69		; The left whisker got hit
.equ	RWhiskyState = 127		; The right whisker got hit
.equ	EWhiskyState = -127		; A whisker got hit, processed, we're at the end

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code
.equ	FreezeTx =   $F8					; Freeze signal from transmiter
.equ	FreezeRx =   $55					; Freeze signal receiver sends

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

;Should have Interrupt vectors for:
;- Right whisker
.org	$0002
		rcall	RWhisker		; Call right whisker
		reti

;- Left whisker
.org	$0004
		rcall	LWhisker		; Call left whisker
		reti

;- Timer 1 normal overflow hahahaHA
.org	$001C
		rcall	CLK_INT
		reti

;- USART receive
.org	$003C
		rcall	USART_RECV		; Call usart receive
		reti

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		;Stack Pointer (VERY IMPORTANT!!!!)
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr

		;I/O Ports

		; Configure Port B as outputs
		ldi		mpr, $FF
		out		DDRB, mpr
		ldi		mpr, $00
		out		PORTB, mpr

		; Configure Port D as pull-up inputs
		ldi		mpr, 0b00000100
		out		DDRD, mpr
		ldi		mpr, 0b11110011
		out		PORTD, mpr

		;USART1
		;Set baudrate at 2400bps
		;Enable receiver and enable receive interrupts
		;Set frame format: 8 data bits, 2 stop bits
		ldi		mpr, $02
		sts		UCSR1A, mpr

		ldi		mpr, 0b10011000
		sts		UCSR1B, mpr
	
		ldi		mpr, 0b10001110
		sts		UCSR1C, mpr

		; Baud rate 2400bps with double
		ldi		mpr, $03
		sts		UBRR1H, mpr
		ldi		mpr, $40
		sts		UBRR1L, mpr

		; Setup all the timers
		; Init speed to 0
		ldi		speed, 1

		; Configure 8-bit Timer/Counters
		ldi		mpr, 0b01111001
		out		TCCR0, mpr		; Initialize TCCR0 for fast pwm mode with 
								; Set OC0 on compare match, clear at bottom
		out		TCCR2, mpr		; Initialize TCCR2 for fast pwm mode with 
								; Set OC2 on compare match, clear at bottom

		mov		mpr, speed
		out		OCR0, mpr		; Initialize compare match of Timer/Counter0 to speed
		out		OCR2, mpr		; Initialize compare match of Timer/Counter0 to speed

		; Enable Overflow interrupt for Timer/Counter1
		ldi		mpr, (1 << 2)	
		out		TIMSK, mpr	
			
		;External Interrupts
		;Set the Interrupt Sense Control to falling edge detection
		ldi		mpr, 0b00001010
		sts		EICRA, mpr			; Set port 0 and 1 to falling edge

		; Configure the External Interrupt Mask
		ldi		mpr, (1 << WskrL | 1 << WskrR)
		out		EIMSK, mpr			; Enable port 0 and 1 for interrupts
		
		; Enable interrupts globally
		sei

		; Init waitcnt to 1 sec
		ldi		waitcnt, WTime

		; Init lit to 0
		ldi		lit, 0

		; Init received to 0
		ldi		received, 0

		; Init number of times froxen 0
		ldi		numbFrozen, 0

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: USART_RECV
; Desc: Moves the TekBot USART recv
;-----------------------------------------------------------
USART_RECV:

		; Save mpr to stack
		push	mpr

		; Load received usart data to mpr
		lds		mpr, UDR1

		; Check if command is freeze sent from other receiver bots
		cpi		mpr, FreezeRx

		; Otherwise jump to check if received data is a bot address or command
		brne	CHECK_RECEIVED

		; Freeze the bot and jump to end of function
		rcall	FREEZE_BOT
		rjmp	END_USART_RECV

CHECK_RECEIVED:

		; Check if a bot address was already received
		cpi		received, 1

		; Process received data as an action code
		breq	ACTION_CODE

		; Check if received data matches this bots address
		cpi		mpr, BotAddress

		; Jump to end of function if doesn't match
		brne	END_USART_RECV

		; Set flag for matching bot address to 1 and jump to end of function
		ldi		received, 1
		rjmp	END_USART_RECV

ACTION_CODE:

		; Set matching bot address flag to 0
		ldi		received, 0

		; Check if action code is freeze
		cpi		mpr, FreezeTx

		; Process action code as non-freeze
		brne	NON_FREEZE

		; Call speed dec if its freeze
		rcall	SET_INC
		jmp		END_USART_RECV

NON_FREEZE:

		; Shift action code left 1 bit and output result to the LEDs
		lsl		mpr

		; Check if its Halt code, if so call speed inc
		cpi		mpr, Halt
		breq	CALL_SPEED_INC

		mov		lit, mpr
		or		lit, speed
		out		PORTB, lit
		rjmp	END_USART_RECV

CALL_SPEED_INC:
		rcall	SET_DEC

END_USART_RECV:

		; Restore mpr from stack
		pop		mpr
		ret

;-----------------------------------------------------------
; Func: RWHISKER
; Desc: When the right whisker is hit, moves the bot back, turns left
;-----------------------------------------------------------
RWHISKER:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr			; Save mpr
		in		mpr, SREG
		push	mpr			; Save the status register

		; Disable all button interrupts
		ldi		mpr, 0
		out		EIMSK, mpr

		; Disable usart interrupts
		ldi		mpr, 0
		sts		UCSR1B, mpr

		; Back up
		ldi		mpr, MovBck
		or		mpr, speed
		out		PORTB, mpr	; Move the bot backwards

		; Load in the whisky state
		ldi		whiskyState, RWhiskyState
		
		; Setup the clock
		rcall	INIT_CLK

		; Restore variable by popping them from the stack in reverse order
		pop		mpr
		out		SREG, mpr	; Restore status register
		pop		mpr			; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: LWHISKER
; Desc: When the left whisker is hit, moves the bot back, turns right
;-----------------------------------------------------------
LWHISKER:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr			; Save mpr
		in		mpr, SREG
		push	mpr			; Save the status register

		; Disable all button interrupts
		ldi		mpr, 0
		out		EIMSK, mpr

		; Disable usart interrupts
		ldi		mpr, 0
		sts		UCSR1B, mpr

		; Back up
		ldi		mpr, MovBck
		or		mpr, speed
		out		PORTB, mpr	; Move the bot backwards

		; Load in the whisky state
		ldi		whiskyState, LWhiskyState
		
		; Setup the clock
		rcall	INIT_CLK

		; Restore variable by popping them from the stack in reverse order
		pop		mpr
		out		SREG, mpr	; Restore status register
		pop		mpr			; Restore mpr

		ret						; End a function with RET

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;-----------------------------------------------------------
; Func: FREEZE_BOT
; Desc: Freezes the bot
;-----------------------------------------------------------
FREEZE_BOT:

		; Save mpr to stack
		push	mpr

		; Output halt code to LEDs
		ldi		mpr, Halt
		out		PORTB, mpr

		; Disable interrupts globally
		cli

		; Incremement times frozen by 1
		inc		numbFrozen

		; If froxen 3 times, disable everything i.e. interrupts
		cpi		numbFrozen, 3
		breq	END_FREEZE

		; Wait for 5 seconds
		rcall	Wait
		rcall	Wait
		rcall	Wait
		rcall	Wait
		rcall	Wait

		; Clear all external interrupts
		ldi		mpr, $FF
		out		EIFR, mpr
		
		; Clear USART interrupts
		lds		mpr, UCSR1A
		ori		mpr, 0b11100000
		sts		UCSR1A, mpr		

		; Enable interrupts globally
		sei

		; Resume what it was doing before freeze
		out		PORTB, lit

END_FREEZE:

		; Restore mpr from stack
		pop		mpr
		ret

;-----------------------------------------------------------
; Func: CLK_INT
; Desc: Interrupt function for timer/counter 1
;-----------------------------------------------------------
CLK_INT:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr			; Save mpr
		in		mpr, SREG
		push	mpr			; Save the status register

		
		cpi		whiskyState, RWhiskyState
		breq	R_WHISKY_STATE

		cpi		whiskyState, LWhiskyState
		breq	L_WHISKY_STATE
		
		rjmp	E_WHISKY_STATE

R_WHISKY_STATE:

		; Turn left
		ldi		mpr, TurnL
		or		mpr, speed
		out		PORTB, mpr	; Turn bot left

		ldi		whiskyState, EWhiskyState

		rcall	INIT_CLK

		rjmp	END_CLK_INT

L_WHISKY_STATE:
		
		; Turn right
		ldi		mpr, TurnR
		or		mpr, speed
		out		PORTB, mpr	; Turn bot left

		ldi		whiskyState, EWhiskyState
				
		rcall	INIT_CLK

		rjmp	END_CLK_INT

E_WHISKY_STATE:

		; Clear queue for buttons
		ldi		mpr, $FF
		out		EIFR, mpr	; Clear the interrupt flags

		; Clear	queue for usart receive
		lds		mpr, UCSR1A
		ori		mpr, 0b10000000
		sts		UCSR1A, mpr

		; Configure the External Interrupt Mask
		ldi		mpr, (1 << WskrL | 1 << WskrR)
		out		EIMSK, mpr			; Enable port 0 and 1 for interrupts

		; Configure USART1 receive interrupt and other things
		ldi		mpr, 0b10011000
		sts		UCSR1B, mpr

		; Disable timer 1
		ldi		mpr, 0
		out		TCCR1B, mpr

		; Restore the previous lights - IT,S LIT!
		or		lit, speed
		out		PORTB, lit

END_CLK_INT:

		; Restore variable by popping them from the stack in reverse order
		pop		mpr
		out		SREG, mpr	; Restore status register
		pop		mpr			; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: INIT_CLK
; Desc: Rustles clocks jimmies
;-----------------------------------------------------------
INIT_CLK:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr			; Save mpr

		; Timer 1 configuration for 1 second normal hahaha
		ldi		mpr, $00		
		out		TCCR1A, mpr		; Initialize TCCR1A for normal mode
		ldi		mpr, 0b00000100
		out		TCCR1B, mpr		; Intialize TCCR1B for normal mode 
								; And a prescale of 256

		; Set high byte of initial value to high byte of InitClkVal
		ldi		mpr, HIGH(InitClkVal)
		out		TCNT1H, mpr

		; Set low byte of initial value to low byte of InitClkVal
		ldi		mpr, LOW(InitClkVal)
		out		TCNT1L, mpr

		; Restore variable by popping them from the stack in reverse order
		pop		mpr			; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: SET_DEC
; Desc: Decrease the speed of the bump bot
;-----------------------------------------------------------
SET_DEC:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr					; Save mpr 
		in		mpr, SREG			; Get Status Register
		push	mpr					; Save Status Register

		cpi		speed, $00			; Compare value of 0 with speed
		breq	SKIP_DEC			; Branch if equal
		dec		speed				; Decrement speed

		in		mpr, PORTB			; Get current values of PORTB
		andi	mpr, $F0			; Clear lower 4 bits of mpr
		or		mpr, speed			; Logical OR current speed with mpr
		out		PORTB, mpr			; write value to PORTB

		rcall	UPD_COMP			; Call Update Compare function

SKIP_DEC:							
		
		; Save waitcnt
		push	waitcnt
		ldi		waitcnt, SpeedIncTime
		rcall	Wait
		pop		waitcnt

		; Clear queue
		ldi		mpr, $0F
		out		EIFR, mpr			; Clear the interrupt flags

		; Restore variable by popping them from the stack in reverse order
		pop		mpr					; Pop mpr
		out		SREG, mpr			; Restore Status Register
		pop		mpr					; Restore mpr

		ret							; End a function with RET

;-----------------------------------------------------------
; Func: SET_INC
; Desc: Increase the speed of the bump bot
;-----------------------------------------------------------
SET_INC:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr					; Save mpr 
		in		mpr, SREG			; Get Status Register
		push	mpr					; Save Status Register

		cpi		speed, $0F			; Compare value of 15 with speed
		breq	SKIP_INC			; Branch if equal
		inc		speed				; Increment speed

		in		mpr, PORTB			; Get current values of PORTB
		andi	mpr, $F0			; Clear lower 4 bits of mpr
		or		mpr, speed			; Logical OR current speed with mpr
		out		PORTB, mpr			; write value to PORTB

		rcall	UPD_COMP			; Call Update Compare function

SKIP_INC:

		; Save waitcnt
		push	waitcnt
		ldi		waitcnt, SpeedIncTime
		rcall	Wait
		pop		waitcnt

		; Clear queue
		ldi		mpr, $0F
		out		EIFR, mpr			; Clear the interrupt flags

		; Restore variable by popping them from the stack in reverse order
		pop		mpr					; Pop mpr
		out		SREG, mpr			; Restore Status Register
		pop		mpr					; Restore mpr

		ret							; End a function with RET

;-----------------------------------------------------------
; Func: UPD_COMP
; Desc: update the compare register for the timers
;-----------------------------------------------------------
UPD_COMP:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr					; Save mpr 
		in		mpr, SREG			; Get Status Register
		push	mpr					; Save Status Register
		push	r0					; Save r0
		push	r1					; Save r1

		ldi		mpr, 17				; Load mpr with value 17
		mul		mpr, speed			; Multiply mpr value with speed
		out		OCR0, r0			; Set compare match of Timer/Counter0 to r0
		out		OCR2, r0			; Set compare match of Timer/Counter2 to r0

		; Restore variable by popping them from the stack in reverse order
		pop		r1					; Restore r1
		pop		r0					; Restore r0
		pop		mpr					; Pop mpr
		out		SREG, mpr			; Restore Status Register
		pop		mpr					; Restore mpr

		ret						; End a function with RET
