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
.def	waitcnt = r17			; Register for wait time
.def	ilcnt = r18				; Inner loop register for wait function
.def	olcnt = r19				; Outer loop register for wait function
.def	memcnt = r20			; Memory counter for whisker hit
.def	prevState = r21			; Previous whisker hit

.equ	WTime = 10				; Wait time for moving
.equ	WTimeLong = 30			; Long wait time for moving
.equ	WTime180 = 255			; Wait time for 180 turn

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit

.equ	EngDirR = 0				; Right motor port
.equ	EngDirL = 1				; Left motor port
.equ	MovFwd = (1 << EngDirR | 1 << EngDirL)		; Motor value for moving forward
.equ	MovBck = $00								; Motor value for moving backward
.equ	TurnR = (1 << EngDirL)						; Motor value for turning right
.equ	TurnL = (1 << EngDirR)						; Motor value for turning left

.equ	StateN = 0				; State for no whiskers hit
.equ	StateL = 1				; State for left whisker hit
.equ	StateR = 2				; State for right whisker hit

.equ	maxHit = 5				; Max alternating whisker hits before doin sumthin special


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

		; Right whisker hit
.org	$0002
		rcall	RWhisker		; Call right whisker
		reti

		; Left whisker hit
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

		ldi		memcnt, 0			; Init memory counter to 0
		ldi		prevState, stateN	; Init prevState to neutral

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

		ldi		mpr, movFwd
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
		push	waitcnt				; Save waitcnt register
		push	mpr					; Save mpr 
		in		mpr, SREG
		push	mpr					; Save status register

		; Init wait count to normal
		ldi		waitcnt, WTime		; Init wait time to wait register

		; Check previous whisker state
		cpi		prevState, stateR
		breq	SameR				; Check if the current whisker state is the same as the previous state

		; Previous whisker state was different, update previous state
		ldi		prevState, stateR

		; Increment mem count, turning around if equal to max hit
		inc		memcnt				; Increase memory count
		cpi		memcnt, maxHit		; Check if the memory count is equal to max
		breq	Turn180R			; Jump to 180 turn if equal
		rjmp	RegularR			; Jump to regular

Turn180R:
		; We need to make 180 turn
		ldi		memcnt, 0			; Set memory count to 0
		rcall	TurnAround			; Call TurnAround function
		rjmp	EndR				; Jump to end

		; Same whisker was hit twice
SameR:
		; Back up and turn twice as long
		ldi		waitcnt, WTimeLong	; Set waitcnt to long time
		ldi		memcnt, 0			; Set memory count to 0

RegularR:
		; Back up
		ldi		mpr, MovBck
		out		PORTB, mpr			; Move bot backward
		rcall	Wait				; Call wait function

		; Turn left
		ldi		mpr, TurnL
		out		PORTB, mpr			; Turn bot left
		rcall	Wait				; Call wait function

EndR:
		; Clear queue
		ldi		mpr, $03
		out		EIFR, mpr			; Clear the interrupt flags

		; Restore variable by popping them from the stack in reverse order
		pop		mpr
		out		SREG, mpr			; Restore mpr
		pop		mpr					; Restore status register
		pop		waitcnt				; Restore waitcnt register

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: LWHISKER
; Desc: When the left whisker is hit, moves the bot back, turns right
;-----------------------------------------------------------
LWHISKER:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	waitcnt				; Save waitcnt register
		push	mpr					; Save mpr
		in		mpr, SREG
		push	mpr					; Save status register

		; Init wait count to normal
		ldi		waitcnt, WTime		; Init wait time to wait register

		; Check previous whisker state
		cpi		prevState, stateL
		breq	SameL				; Check if the current whisker state is the same as the previous state

		; Previous whisker state was different, update previous state
		ldi		prevState, stateL

		; Increment mem count, turning around if equal to max hit
		inc		memcnt				; Increase memory count
		cpi		memcnt, maxHit		; Check if the memory count is equal to max
		breq	Turn180L			; Jump to 180 turn if equal
		rjmp	RegularL			; Jump to regular

Turn180L:
		; We need to make 180 turn
		ldi		memcnt, 0			; Set memory count to 0
		rcall	TurnAround			; Call TurnAround function
		rjmp	EndL				; Jump to end

		; Same whisker was hit twice
SameL:
		; Back up and turn twice as long
		ldi		waitcnt, WTimeLong	; Set waitcnt to long time
		ldi		memcnt, 0			; Set memory count to 0

RegularL:
		; Back up
		ldi		mpr, MovBck
		out		PORTB, mpr			; Move bot backward
		rcall	Wait				; Call wait function

		; Turn right
		ldi		mpr, TurnR
		out		PORTB, mpr			; Turn bot right
		rcall	Wait				; Call wait function

EndL:
		; Clear queue
		ldi		mpr, $03
		out		EIFR, mpr			; Clear the interrupt flags

		; Restore variable by popping them from the stack in reverse order
		pop		mpr
		out		SREG, mpr			; Restore mpr
		pop		mpr					; Restore status register
		pop		waitcnt				; Restore waitcnt register

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

;----------------------------------------------------------------
; Sub:	TurnAround
; Desc:	
;----------------------------------------------------------------
TurnAround:
		; Save variable by pushing them to the stack
		push	mpr					; Save mpr
		push	waitcnt				; Save waitcnt register

		; Back up
		ldi		mpr, MovBck
		out		PORTB, mpr			; Move bot backwards
		ldi		waitcnt, WTime		; Set waitcnt to wait time
		rcall	Wait				; Call wait function

		; Turn 180
		ldi		mpr, TurnR
		out		PORTB, mpr			; Turn right
		ldi		waitcnt, WTime180	; Set waitcnt to turn around
		rcall	Wait				; Call wait function

		; Restore variable by popping them from the stack in reverse order
		pop		waitcnt				; Restore waitcnt register
		pop		mpr					; Restore mpr

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program