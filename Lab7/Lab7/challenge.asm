;***********************************************************
;*
;*	main.asm
;*
;*	Similiar behaviour to the BasicBumpBot.asm program,
;*	except there is variable speed of the motors and the LCD
;*  is utilized to display speed.
;*
;*
;***********************************************************
;*
;*	 Author: Aidan Carson and Fauzi Kliman
;*	   Date: 2/21/18
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
.def	speed = r20
.def	clk = r21
.def	temp1 = r23
.def	temp2 = r24

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit
.equ	MovFwd = (1 << EngDirR | 1 << EngDirL)		; Motor value for moving forward
.equ	InitClkVal = 3036		; Initial value of LCD clk for timer 1
.equ	LCDMem1 = $0100			; Start address of lcd memory address line 1

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

		; place instructions in interrupt vectors here, if needed
		
.org	$0002
		rcall	SET_MIN			; Set minimum speed interrupt vector
		reti					; Return from interrupt

.org	$0004
		rcall	SET_DEC			; Set decrement speed interrupt vector
		reti					; Return from interrupt

.org	$0006
		rcall	SET_INC			; Set increment speed interrupt vector
		reti					; Return from interrupt

.org	$0008
		rcall	SET_MAX			; Set minimum speed interrupt vector
		reti					; Return from interrupt

.org	$001C
		rcall	INC_CLK			; Increment clock interrupt vector
		reti					; Return from interrupt

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi		mpr, low(RAMEND)	; Get the low byte of the ram
		out		SPL, mpr			; Set stack pointer low to low byte of ram
		ldi		mpr, high(RAMEND)	; Get the high byte of the ram
		out		SPH, mpr			; Set stack pointer high to high byte of ram


		ldi		speed, $00			; Initialize speed variable

		; Configure I/O ports

		; Configure Port B pins 4 - 7 for output
		ldi		mpr, $FF
		out		DDRB, mpr		; Set DDRB for output
		ldi		mpr, $00
		out		PORTB, mpr		; Initialize PORTB to 0

		or		mpr, speed		
		out		PORTB, mpr		; Load initial value of speed in output

		; Configure Port D pins 3 - 0 for input
		ldi		mpr, $00
		out		DDRD, mpr		; Set DDRD for input
		ldi		mpr, $FF
		out		PORTD, mpr		; Set PORTD for pull-up

		; Configure External Interrupts
		ldi		mpr, 0b10101010
		sts		EICRA, mpr		; Configure EICRA for falling edge

		ldi		mpr, $0F
		out		EIMSK, mpr		; Configure EIMSK to listen for inputs on bits 0 - 3


		; Configure 8-bit Timer/Counters
		ldi		mpr, 0b01101001
		out		TCCR0, mpr		; Initialize TCCR0 for fast pwm mode with 
								; clear OC0 on compare match, set at bottom
		out		TCCR2, mpr		; Initialize TCCR2 for fast pwm mode with 
								; clear OC2 on compare match, set at bottom

		mov		mpr, speed
		out		OCR0, mpr		; Initialize compare match of Timer/Counter0 to speed
		out		OCR2, mpr		; Initialize compare match of Timer/Counter0 to speed

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL)
		; Set initial speed, display on Port B pins 3:0
		ldi		mpr, MovFwd
		out		PORTB, mpr		; Intialize Tekbot to move forward

		ldi		waitcnt, 20	; Set wait time to .2 seconds

		; Enable global interrupts (if any are used)
		sei						; Set global interrupt

		rcall	LCDInit			; Initialize LCD

		ldi		clk, $00		; Initialize clk

		ldi		XH, HIGH(LCDMem1) ; Initialize upper byte of X
		ldi		XL, LOW(LCDMem1)  ; Initialie lower byte of X

		ldi		mpr, $00		
		out		TCCR1A, mpr		; Initialize TCCR1A for normal mode
		ldi		mpr, 0b00000100
		out		TCCR1B, mpr		; Intialize TCCR1B for normal mode 
								; And a prescale of 256

		ldi		mpr, HIGH(InitClkVal)
		out		TCNT1H, mpr		; Set high byte of initial value to
								; High byte of InitClkVal
		ldi		mpr, LOW(InitClkVal)
		out		TCNT1L, mpr		; Set low byte of initial value to
								; Low byte of InitClkVal

		ldi		mpr, (1 << 2)	
		out		TIMSK, mpr		; Enable Overflow interrupt for
								; Timer/Counter1

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		
		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: SET_MIN
; Desc: Set the speed of the bump bot to 0
;-----------------------------------------------------------
SET_MIN:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr					; Save mpr 
		in		mpr, SREG			; Get Status Register
		push	mpr					; Save Status Register

		ldi		speed, $00			; Load value of 0 into speed

		in		mpr, PORTB			; Get current values of PORTB
		andi	mpr, $F0			; Clear lower 4 bits of mpr
		or		mpr, speed			; Logical OR current speed with mpr
		out		PORTB, mpr			; write value to PORTB

		rcall	UPD_COMP			; Call Update Compare function

		ldi		clk, $00			; Reset clk back to 0

		rcall	INT_WAIT			; Call Wait function
		; Clear queue
		ldi		mpr, $0F
		out		EIFR, mpr			; Clear the interrupt flags

		; Restore variable by popping them from the stack in reverse order
		pop		mpr					; Pop mpr
		out		SREG, mpr			; Restore Status Register
		pop		mpr					; Restore mpr

		ret							; End a function with RET

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
		ldi		clk, $00			; Reset clk back to 0

		rcall	INT_WAIT			; Call Wait function
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
		ldi		clk, $00			; Reset clk back to 0

		rcall	INT_WAIT			; Call Wait function
		; Clear queue
		ldi		mpr, $0F
		out		EIFR, mpr			; Clear the interrupt flags

		; Restore variable by popping them from the stack in reverse order
		pop		mpr					; Pop mpr
		out		SREG, mpr			; Restore Status Register
		pop		mpr					; Restore mpr

		ret							; End a function with RET

;-----------------------------------------------------------
; Func: SET_MAX
; Desc: Set the speed of the bump bot to max
;-----------------------------------------------------------
SET_MAX:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr					; Save mpr 
		in		mpr, SREG			; Get Status Register
		push	mpr					; Save Status Register

		ldi		speed, $0F			; Load value of 15 into speed

		in		mpr, PORTB			; Get current values of PORTB
		andi	mpr, $F0			; Clear lower 4 bits of mpr
		or		mpr, speed			; Logical OR current speed with mpr
		out		PORTB, mpr			; write value to PORTB

		rcall	UPD_COMP			; Call Update Compare function

		ldi		clk, $00			; Reset clk back to 0

		rcall	INT_WAIT			; Call Wait function

		; Clear queue
		ldi		mpr, $0F			; Clear the interrupt flags
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

;-----------------------------------------------------------
; Func: INC_CLK
; Desc: Increment clk used to display time since last button press
;-----------------------------------------------------------
INC_CLK:							; Begin a function with a label

		; Save variable by pushing them to the stack
		push	mpr					; Save mpr 
		in		mpr, SREG			; Get Status Register
		push	mpr					; Save Status Register
		push	ilcnt				; Save ilcnt
		push	clk					; Save clk

		rcall	LCDClr				; Clear LCD

		ldi		ilcnt, 7			; Load loop
		ldi		mpr, 0				; Initialize mpr

CLK_LOOP:
		dec		ilcnt				; Decrement ilcnt
		rol		clk					; Rotate clk left through carry
		brcc	BEG_WRITE			; Branch if carry cleared

		ldi		mpr, 1				; Load 1 into mpr
BEG_WRITE:
		ldi		temp1, $00			; Load temp1 with immediate
		ldi		temp2, 48			; Load temp2 with immediate
		adc		temp1, temp2		; Add with carry temp1 and temp2

		cpi		mpr, 1				; Compare immediate
		brne	END_WRITE			; Branch if not equal

		st		X+, temp1			; Write to memory for LCD to access

END_WRITE:
		cpi		ilcnt, 0			; Compare immediate
		brne	CLK_LOOP			; Branch if not equal

		rol		clk					; Rotate left clk through carry
		ldi		temp1, $00			; Load temp1 with immediate
		ldi		temp2, 48			; Load temp2 with immediate
		adc		temp1, temp2		; Add with carry temp1 and temp2
		st		X+, temp1			; Write to memory for LCD to access regardless

		rcall	LCDWrite			; Call LCD write function
		ldi		XH, HIGH(LCDMem1)	; Reset XH to LCD memory start location
		ldi		XL, LOW(LCDMem1)	; Reset XL to LCD memory start location

		ldi		mpr, HIGH(InitClkVal)
		out		TCNT1H, mpr			; Reset TCNT1H back to high byte of InitClkVal
		ldi		mpr, LOW(InitClkVal)
		out		TCNT1L, mpr			; Reset TCNT1L back to low byte of InitClkVal

		; Restore variable by popping them from the stack in reverse order
		pop		clk					; Restore clk
		inc		clk					; Increment clk
		pop		ilcnt				; Restore ilcnt
		pop		mpr					; Pop mpr
		out		SREG, mpr			; Restore Status Register
		pop		mpr					; Restore mpr

		ret						; End a function with RET

;----------------------------------------------------------------
; Sub:	INT_WAIT
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clk cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
INT_WAIT:
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
.include "LCDDriver.asm"		; Include the LCD Driver
