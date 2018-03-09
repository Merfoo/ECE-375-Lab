;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	lit = r17				; Register for light
.def	rFlag = r18				; Flag for address recieved

.def	waitcnt = r19			; Register for wait time
.def	ilcnt = r20				; Inner loop register for wait function
.def	olcnt = r21				; Outer loop register for wait function

.equ	WTime = 100;			; Wait time for moving

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = $2A;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code

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

;- USART receive
.org	$003C
		rcall	USART_RECV
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

		ldi		mpr, 0b10010000
		sts		UCSR1B, mpr
	
		ldi		mpr, 0b10001110
		sts		UCSR1C, mpr

		; Baud rate 2400bps with double
		ldi		mpr, $03
		sts		UBRR1H, mpr
		ldi		mpr, $40
		sts		UBRR1L, mpr

		; From transmit file

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

		; Init lit
		ldi		lit, 0

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;TODO: ???
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: USART_RECV
; Desc: Moves the TekBot USART recv
;-----------------------------------------------------------
USART_RECV:
		push	mpr
		lds		mpr, UDR1

		cpi		rFlag, 1
		breq	CHECK_HALT

		cpi		mpr, BotAddress
		brne	END_RECV_ADDR
		ldi		rFlag, 1
		rjmp	END
END_RECV_ADDR:
		ldi		rFlag, 0
		rjmp	END

CHECK_HALT:
		rol		mpr
		ldi		rFlag, 0

		cpi		mpr, Halt
		brne	CHECK_BCK
		ldi		lit, Halt
		out		PORTB, lit
		rjmp	END

CHECK_BCK:
		cpi		mpr, MovBck
		brne	CHECK_FWD
		ldi		lit, MovBck
		out		PORTB, lit
		rjmp	END

CHECK_FWD:
		cpi		mpr, MovFwd
		brne	CHECK_RIGHT
		ldi		lit, MovFwd
		out		PORTB, lit
		rjmp	END

CHECK_RIGHT:
		cpi		mpr, TurnR
		brne	CHECK_LEFT
		ldi		lit, TurnR
		out		PORTB, lit
		rjmp	END

CHECK_LEFT:
		cpi		mpr, TurnL
		brne	END
		ldi		lit, TurnL
		out		PORTB, lit
		rjmp	END

END:
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

		; Back up
		ldi		mpr, MovBck
		out		PORTB, mpr	; Move the bot backwards
		rcall	Wait		; Call wait function

		; Turn left
		ldi		mpr, TurnL
		out		PORTB, mpr	; Turn bot left
		rcall	Wait		; Call wait function

		; Clear queue
		ldi		mpr, $03
		out		EIFR, mpr	; Clear the interrupt flags

		out		PORTB, lit

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

		; Back up
		ldi		mpr, MovBck
		out		PORTB, mpr	; Move the bot backwards
		rcall	Wait		; Call wait function

		; Turn right
		ldi		mpr, TurnR
		out		PORTB, mpr	; Turn bot left
		rcall	Wait		; Call wait function

		; Clear queue
		ldi		mpr, $03
		out		EIFR, mpr	; Clear the interrupt flags

		out		PORTB, lit

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

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
