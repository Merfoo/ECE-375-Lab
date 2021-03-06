;***********************************************************
;*
;*	main.asm
;*
;*	Similiar behaviour to the BasicBumpBot.asm program,
;*	except that whisker inputs are handle via interrupts
;*	instead of polling
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Fauzi Kliman and Aidan Carson
;*	   Date: 2/13/2018
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	waitcnt = r17			; Register for wait time
.def	ilcnt = r18				; Inner loop register for wait function
.def	olcnt = r19				; Outer loop register for wait function

.equ	WTime = 500;			; Wait time for moving

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit

.equ	EngDirR = 0				; Right motor port
.equ	EngDirL = 1				; Left motor port
.equ	MovFwd = (1 << EngDirR | 1 << EngDirL)		; Motor value for moving forward
.equ	MovBck = $00								; Motor value for moving backward
.equ	TurnR = (1 << EngDirL)						; Motor value for turning right
.equ	TurnL = (1 << EngDirR)						; Motor value for turning left

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used

		; Right whisker
.org	$0002
		rcall	RWhisker		; Call right whisker
		reti

		; Left whisker
.org	$0004
		rcall	LWhisker		; Call left whisker
		reti

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)	; Get the low byte of the ram
		out		SPL, mpr			; Set stack pointer low to low byte of ram
		ldi		mpr, high(RAMEND)	; Get the high byte of the ram
		out		SPH, mpr			; Set stack pointer high to high byte of ram

		; Initialize Port B for output
		ldi		mpr, $FF
		out		DDRB, mpr			; Set port B to output
		ldi		mpr, $00
		out		PORTB, mpr			; Init port B to 0

		; Initialize Port D for input
		ldi		mpr, ~(1 << WskrL | 1 << WskrR)
		out		DDRD, mpr			; Set whisker ports on D to output
		ldi		mpr, $FF
		out		PORTD, mpr			; Set input mode to pull-up

		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge 
		ldi		mpr, 0b00001010
		sts		EICRA, mpr			; Set port 0 and 1 to falling edge

		; Configure the External Interrupt Mask
		ldi		mpr, (1 << WskrL | 1 << WskrR)
		out		EIMSK, mpr			; Enable port 0 and 1 for interrupts

		; Turn on interrupts
			; NOTE: This must be the last thing to do in the INIT function
		sei							; Enable the global interrupt flag

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		ldi		mpr, movfwd
		out		portb, mpr		; Move the bot forward

		rjmp	MAIN			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the 
;	left whisker interrupt, one to handle the right whisker 
;	interrupt, and maybe a wait function
;------------------------------------------------------------

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

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program