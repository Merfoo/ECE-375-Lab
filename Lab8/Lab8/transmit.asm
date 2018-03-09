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

		;Other
		ldi		addr, $2A

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		
		in		mpr, PIND
		com		mpr

		sbrs	mpr, PD0
		rjmp	CHECK_BCK
		ldi		buf, Halt
		rcall	SEND_BUF

		out		PORTB, buf
		rjmp	END
CHECK_BCK:
		sbrs	mpr, PD1
		rjmp	CHECK_FWD
		ldi		buf, MovBck
		rcall	SEND_BUF

		out		PORTB, buf
		rjmp	END
CHECK_FWD:
		sbrs	mpr, PD4
		rjmp	CHECK_RIGHT
		ldi		buf, MovFwd
		rcall	SEND_BUF

		out		PORTB, buf
		rjmp	END
CHECK_RIGHT:
		sbrs	mpr, PD5
		rjmp	CHECK_LEFT
		ldi		buf, TurnR
		rcall	SEND_BUF

		out		PORTB, buf
		rjmp	END
CHECK_LEFT:
		sbrs	mpr, PD6
		rjmp	END
		ldi		buf, TurnL
		rcall	SEND_BUF

		out		PORTB, buf
		rjmp	END
END:
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: SEND_BUF
; Desc: Moves the TekBot halt
;-----------------------------------------------------------
SEND_BUF:
		push	mpr

SEND_ADDR:
		lds		mpr, UCSR1A
		sbrs	mpr, UDRE1
		rjmp	SEND_ADDR
		sts		UDR1, addr

SEND_DATA:
		lds		mpr, UCSR1A
		sbrs	mpr, UDRE1
		rjmp	SEND_DATA
		sts		UDR1, buf

		pop		mpr
		ret

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
