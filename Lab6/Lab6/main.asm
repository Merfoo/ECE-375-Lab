;***********************************************************
;*
;*	main.asm
;*
;*	Similiar behaviour to the BasicBumpBot.asm program,
;*	except that whisker inputs are handled via interrupts
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
.def	waitcnt = r17
.def	ilcnt = r18
.def	olcnt = r19

.equ	WTime = 200;

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit

.equ	EngDirR = 0				
.equ	EngDirL = 1
.equ	MovFwd = (1 << EngDirR | 1 << EngDirL)
.equ	MovBck = $00
.equ	TurnR = (1 << EngDirL)
.equ	TurnL = (1 << EngDirR)

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
		rcall	RWhisker
		reti

		; Left whisker
.org	$0004
		rcall	LWhisker
		reti

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		
		ldi		waitcnt, WTime

		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		; Initialize Port B for output
		ldi		mpr, $FF
		out		DDRB, mpr
		ldi		mpr, $00
		out		PORTB, mpr

		; Initialize Port D for input
		ldi		mpr, ~(1 << WskrL | 1 << WskrR)
		out		DDRD, mpr
		ldi		mpr, $FF
		out		PORTD, mpr

		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge 
		ldi		mpr, 0b00001010
		sts		EICRA, mpr

		; Configure the External Interrupt Mask
		ldi		mpr, (1 << WskrL | 1 << WskrR)
		out		EIMSK, mpr

		; Turn on interrupts
			; NOTE: This must be the last thing to do in the INIT function
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		; TODO: ???
		ldi		mpr, movfwd
		out		portb, mpr		

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
		push	mpr
		in		mpr, SREG
		push	mpr

		; Back up
		ldi		mpr, MovBck
		out		PORTB, mpr
		rcall	Wait

		; Turn left
		ldi		mpr, TurnL
		out		PORTB, mpr
		rcall	Wait

		; Restore variable by popping them from the stack in reverse order
		pop		mpr
		out		SREG, mpr
		pop		mpr

		; Clear queue
		ldi		mpr, $03
		out		EIFR, mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: LWHISKER
; Desc: When the left whisker is hit, moves the bot back, turns right
;-----------------------------------------------------------
LWHISKER:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr
		in		mpr, SREG
		push	mpr

		; Back up
		ldi		mpr, MovBck
		out		PORTB, mpr
		rcall	Wait

		; Turn right
		ldi		mpr, TurnR
		out		PORTB, mpr
		rcall	Wait

		; Restore variable by popping them from the stack in reverse order
		pop		mpr
		out		SREG, mpr
		pop		mpr

		; Clear queue
		ldi		mpr, $03
		out		EIFR, mpr

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