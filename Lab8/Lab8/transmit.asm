;***********************************************************
;*
;*	transmit.asm
;*
;*	Transmits data to another TekBot
;*
;*	This is the TRANSMIT skeleton file for Lab 8 of ECE 375
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
.def	buf = r17				; Buffer for USARRRRRRRT 1
.def	addr = r18				; Address for robottttttt

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code
.equ	Freeze =   $F8									; Freeze signal from transmiter

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

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
		ldi		mpr, 0b00001000
		out		DDRD, mpr
		ldi		mpr, 0b11110011
		out		PORTD, mpr

		;USART1
		;Set baudrate at 2400bps
		;Enable transmitter
		;Set frame format: 8 data bits, 2 stop bits
		ldi		mpr, $02
		sts		UCSR1A, mpr

		ldi		mpr, 0b00001000
		sts		UCSR1B, mpr
	
		ldi		mpr, 0b00001110
		sts		UCSR1C, mpr

		; Baud rate 2400bps with double
		ldi		mpr, $03
		sts		UBRR1H, mpr
		ldi		mpr, $40
		sts		UBRR1L, mpr

		; Init bot address
		ldi		addr, $2A

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		
		; Load PIND to mpr
		in		mpr, PIND

		; Invert it so that the button input becomes active-high passive-low
		com		mpr

		; Check if pin 0 is set
		sbrs	mpr, PD0

		; Jump to check for move back if pin 0 not set
		rjmp	CHECK_BCK

		; Load halt code to buf and send it
		ldi		buf, Halt
		rcall	SEND_BUF

		; Output halt code to LEDs
		out		PORTB, buf
		rjmp	END
CHECK_BCK:

		; Check if pin 1 is set
		sbrs	mpr, PD1

		; Jump to check move forward if pin 1 not set
		rjmp	CHECK_FWD

		; Load move back code to buf and send it
		ldi		buf, MovBck
		rcall	SEND_BUF

		; Output move back code to LEDs
		out		PORTB, buf
		rjmp	END
CHECK_FWD:

		; Check if pin 4 is set
		sbrs	mpr, PD4

		; Jump to check for turn right if pin 4 is not set
		rjmp	CHECK_RIGHT

		; Load turn right code to buf and send it
		ldi		buf, MovFwd
		rcall	SEND_BUF

		; Output move forward code to LEDs
		out		PORTB, buf
		rjmp	END
CHECK_RIGHT:

		; Check if pin 5 is set
		sbrs	mpr, PD5

		; Jump to check for turn left if pin 5 is not set
		rjmp	CHECK_LEFT

		; Load turn right code to buf and send it
		ldi		buf, TurnR
		rcall	SEND_BUF

		; Output turn right code to LEDs
		out		PORTB, buf
		rjmp	END
CHECK_LEFT:

		; Check if pin 6 is set
		sbrs	mpr, PD6

		; Jump to check freeze if pin 6 is not set
		rjmp	CHECK_FREEZE

		; Load turn left code to buf and send it
		ldi		buf, TurnL
		rcall	SEND_BUF

		; Output turn left code to LEDs
		out		PORTB, buf
		rjmp	END
CHECK_FREEZE:

		; Check if pin 7 is set
		sbrs	mpr, PD7

		; Jump to END if pin 7 is not set
		rjmp	END

		; Load freeze code to buf and send it
		ldi		buf, Freeze
		rcall	SEND_BUF

		; Output freeze code to LEDs
		out		PORTB, buf
		rjmp	END
END:
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: SEND_BUF
; Desc: Send data in buf to usart after sending this bots address
;-----------------------------------------------------------
SEND_BUF:

		; Save mpr to stack
		push	mpr

SEND_ADDR:

		; Check if the empty flag is set for usart
		lds		mpr, UCSR1A

		; Skip next instruction if usart empty flag is set
		sbrs	mpr, UDRE1

		; Loop if the flag is not set i.e. not empty
		rjmp	SEND_ADDR

		; Load this bot address to usart for transmission
		sts		UDR1, addr

SEND_DATA:

		; Check if the empty flag is set for usart
		lds		mpr, UCSR1A

		; Skip next instruction if usart empty flag is set
		sbrs	mpr, UDRE1

		; Loop if the flag is not set i.e. not empty
		rjmp	SEND_DATA

		; Load data in buf to usart for transmission
		sts		UDR1, buf

		; Restore mpr from stack
		pop		mpr
		ret
