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
.def	received = r18			; Flag for address recieved
.def	numbFrozen = r22		; Number of times bot froxen

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
.equ	FreezeTx =   $F8	; Freeze signal from transmiter
.equ	FreezeRx =   $55	; Freeze signal receiver sends

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

		ldi		mpr, 0b10011000
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

		; Init received to 0
		ldi		received, 0

		; Init number of times froxen 0
		ldi		numbFrozen, 0

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

		cpi		mpr, FreezeRx
		brne	CHECK_RECEIVED
		rcall	FREEZE_BOT
		rjmp	END

CHECK_RECEIVED:
		cpi		received, 1
		breq	ACTION_CODE

		cpi		mpr, BotAddress
		brne	END
		ldi		received, 1
		rjmp	END

ACTION_CODE:
		ldi		received, 0

		cpi		mpr, FreezeTx
		brne	NON_FREEZE
		rcall	SEND_FREEZE
		jmp		END

NON_FREEZE:
		lsl		mpr
		mov		lit, mpr
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

;-----------------------------------------------------------
; Func: SEND_FREEZE
; Desc: Sends the freeze signal to other botsss
;-----------------------------------------------------------
SEND_FREEZE:
		push	mpr

		cli
SEND_DATA:
		lds		mpr, UCSR1A
		sbrs	mpr, UDRE1
		rjmp	SEND_DATA
		ldi		mpr, FreezeRx
		sts		UDR1, mpr
		
		rcall	Wait

		; Clear USART interrupts
		lds		mpr, UCSR1A
		ori		mpr, 0b11100000
		sts		UCSR1A, mpr

		sei

		pop		mpr
		ret

;-----------------------------------------------------------
; Func: FREEZE_BOT
; Desc: Freezes the bot
;-----------------------------------------------------------
FREEZE_BOT:
		push	mpr

		; Halt bot
		ldi		mpr, Halt
		out		PORTB, mpr

		; Disable global interrupts
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

		; Clear external interrupts
		ldi		mpr, $FF
		out		EIFR, mpr
		
		; Clear USART interrupts
		lds		mpr, UCSR1A
		ori		mpr, 0b11100000
		sts		UCSR1A, mpr		

		; Enable global interrupts
		sei

		; Resume what it was doing before freeze
		out		PORTB, lit

END_FREEZE:
		pop		mpr
		ret

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
