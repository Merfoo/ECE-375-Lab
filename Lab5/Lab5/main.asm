;***********************************************************
;*
;*	main.asm
;*
;*	Arithmetic operations
;*
;*	This is the skeleton file for Lab 5 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Aidan Carson and Fauzi Kliman
;*	   Date: 2/6/18
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr

		; TODO					; Init the 2 stack pointer registers

		clr		zero			; Set the zero register to zero, maintain
								; these semantics, meaning, don't
								; load anything else into it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
		; Setup the ADD16 function direct test

		; Move values 0xA2FF and 0xF477 in program memory to data memory
		; memory locations where ADD16 will get its inputs from
		; (see "Data Memory Allocation" section below)

		ldi		ZH, HIGH(AddOp1 << 1) ; Load high byte of operand into high byte of register
		ldi		ZL, LOW(AddOp1 << 1)  ; Load low byte of operand into high byte of register
		lpm		R16, Z+				  ; Load from Z register to R16
		lpm		R17, Z				  ; Load from Z register to R17

		ldi		ZH, HIGH(AddOp2 << 1) ; Load high byte of operand into high byte of register
		ldi		ZL, LOW(AddOp2 << 1)  ; Load low byte of operand into high byte of register
		lpm		R18, Z+				  ; Load from Z register to R18
		lpm		R19, Z				  ; Load from Z register to R17

		; Load beginning address of first operand into X
		ldi		XL, low(ADD16_OP1)	; Load low byte of address
		ldi		XH, high(ADD16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(ADD16_OP2)	; Load low byte of address
		ldi		YH, high(ADD16_OP2)	; Load high byte of address

		; Load beginning address of result into Z

		ldi		ZH, HIGH(ADD16_Result) ; Load high byte of result into high byte of register
		ldi		ZL, LOW(ADD16_Result)  ; Load low byte of result into high byte of register

		st		X+, R16		; Store R16 into where X points with post increment
		st		X, R17		; Store R17 into where X points
		st		Y+, R18		; Store R18 into where Y points with post increment
		st		Y, R19 		; Store R19 into where Y points

		; Check load ADD16 operands (Set Break point here #1) 
		; Call ADD16 function to test its correctness					
		; (calculate A2FF + F477)
		RCALL	ADD16
 
        nop ; Check ADD16 result (Set Break point here #2)
		; Observe result in Memory window

		; Setup the SUB16 function direct test

		
		; Move values 0xF08A and 0x4BCD in program memory to data memory
		; memory locations where SUB16 will get its inputs from

		; Execute the function here
		ldi		ZH, HIGH(SubOp1 << 1)	; Load high byte of operand into high byte of register	
		ldi		ZL, LOW(SubOp1 << 1)	; Load low byte of operand into high byte of register	
		lpm		R16, Z+					; Load from Z register to R16
		lpm		R17, Z					; Load from Z register to R17

		ldi		ZH, HIGH(SubOp2 << 1)	; Load high byte of operand into high byte of register	
		ldi		ZL, LOW(SubOp2 << 1)	; Load low byte of operand into high byte of register	
		lpm		R18, Z+					; Load from Z register to R18
		lpm		R19, Z					; Load from Z register to R17

		; Load beginning address of first operand into X
		ldi		XL, low(SUB16_OP1)	    ; Load low byte of address
		ldi		XH, high(SUB16_OP1)	    ; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP2)	    ; Load low byte of address
		ldi		YH, high(SUB16_OP2)	    ; Load high byte of address

		; Load beginning address of result into Z

		ldi		ZH, HIGH(SUB16_Result)	; Load high byte of operand into high byte of register
		ldi		ZL, LOW(SUB16_Result)	; Load low byte of operand into high byte of register
										
		st		X+, R16		; Store R16 into where X points with post increment
		st		X, R17		; Store R17 into where X points
		st		Y+, R18		; Store R18 into where Y points with post increment
		st		Y, R19		; Store R19 into where Y points

		; Check load SUB16 operands (Set Break point here #3)
		; Call SUB16 function to test its correctness
        ; (calculate F08A - 4BCD)
		RCALL	SUB16
				
        nop ; Check SUB16 result (Set Break point here #4)
		; Observe result in Memory window

		; Setup the MUL24 function direct test

		; Move values 0xFFFFFF and 0xFFFFFF in program memory to data memory  
		; memory locations where MUL24 will get its inputs from

		ldi		ZH, HIGH(MulOp1 << 1) ; Load high byte of operand into high byte of register	
		ldi		ZL, LOW(MulOp1 << 1)  ; Load low byte of operand into high byte of register	
		lpm		R16, Z+				  ; Load from Z register to R16
		lpm		R17, Z+				  ; Load from Z register to R17
		lpm		R18, Z				  ; Load from Z register to R18
									  
		ldi		ZH, HIGH(MulOp2 << 1) ; Load high byte of operand into high byte of register
		ldi		ZL, LOW(MulOp2 << 1)  ; Load low byte of operand into high byte of register	
		lpm		R19, Z+				  ; Load from Z register to R19	
		lpm		R20, Z+				  ; Load from Z register to R20
		lpm		R21, Z				  ; Load from Z register to R21

		; Load beginning address of first operand into X
		ldi		XL, low(MUL24_OP1)	; Load low byte of address
		ldi		XH, high(MUL24_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(MUL24_OP2)	; Load low byte of address
		ldi		YH, high(MUL24_OP2)	; Load high byte of address

		; Load beginning address of result into Z

		ldi		ZH, HIGH(MUL24_Result) ; Load high byte of result into high byte of register
		ldi		ZL, LOW(MUL24_Result)  ; Load low byte of result into high byte of register

		st		X+, R16		; Store R16 into where X points with post increment
		st		X+, R17		; Store R17 into where X points with post increment
		st		X+, R18		; Store R18 into where X points with post increment
		st		Y+, R19		; Store R19 into where Y points with post increment
		st		Y+, R20		; Store R20 into where Y points with post increment
		st		Y+, R21		; Store R21 into where Y points with post increment

		; Check load MUL24 operands (Set Break point here #5)
		; Call MUL24 function to test its correctness
        ; (calculate FFFFFF * FFFFFF)
		RCALL	MUL24

        nop ; Check MUL24 result (Set Break point here #6)
		; Observe result in Memory window

		ldi		ZH, HIGH(OperandD << 1)	; Load high byte of operand D into Z register
		ldi		ZL, LOW(OperandD << 1)	; Load low byte of operand D into Z register

		lpm		R16, Z+					; Load R16 from operand D
		lpm		R17, Z					; Load R17 from operand D

		ldi		ZH, HIGH(COMP_OP1)		; Load high byte of sub operand 1 into Z register
		ldi		ZL, LOW(COMP_OP1)		; Load low byte of sub operand 1 into Z register

		st		Z+, R16					; Store R16 into sub operand 1
		st		Z, R17					; Store R17 into sub operand 1

		ldi		ZH, HIGH(OperandE << 1)	; Load high byte of operand E into Z register
		ldi		ZL, LOW(OperandE << 1)	; Load low byte of operand E into Z register

		lpm		R16, Z+					; Load R16 from operand E
		lpm		R17, Z					; Load R17 from operand E

		ldi		ZH, HIGH(COMP_OP2)		; Load high byte of sub operand 2 into Z register
		ldi		ZL, LOW(COMP_OP2)		; Load low byte of sub operand 2 into Z register

		st		Z+, R16					; Store R16 into sub operand 1
		st		Z, R17					; Store R17 into sub operand 1

		ldi		ZH, HIGH(OperandF << 1)	; Load high byte of operand F into Z register
		ldi		ZL, LOW(OperandF << 1)	; Load low byte of operand F into Z register

		lpm		R16, Z+					; Load R16 from operand F
		lpm		R17, Z					; Load R17 from operand F

		ldi		ZH, HIGH(COMP_OP3)		; Load high byte of add operand 2 into Z register
		ldi		ZL, LOW(COMP_OP3)		; Load low byte of add operand 2 into Z register

		st		Z+, R16					; Store R16 into sub operand 1
		st		Z, R17					; Store R17 into sub operand 1

        nop ; Check load COMPOUND operands (Set Break point here #7)  

		; Call the COMPOUND function
		RCALL COMPOUND

        nop ; Check COMPUND result (Set Break point here #8)
		; Observe final result in Memory window

DONE:	rjmp	DONE			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
ADD16:
		; Load beginning address of first operand into X
		ldi		XL, low(ADD16_OP1)	; Load low byte of address
		ldi		XH, high(ADD16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(ADD16_OP2)	; Load low byte of address
		ldi		YH, high(ADD16_OP2)	; Load high byte of address

		; Load beginning address of result into Z

		ldi		ZH, HIGH(ADD16_Result) ; Load high byte of address
		ldi		ZL, LOW(ADD16_Result)  ; Load low byte of address

		ld		R16, X+		; load R16 from operand 1
		ld		R17, X		; load R17 from operand 1
		ld		R18, Y+		; load R18 from operand 2
		ld		r19, Y		; load R19 from operand 2

		; Execute the function

		add		R16, R18	; Add registers
		st		Z+, R16		; Store R16 into Z with post increment

		adc		R17, R19	; Add registers with carry
		st		Z+, R17		; Store R16 into Z with post increment

		clr		R20
		adc		R20, zero
		st		Z, R20		; Store R20 to Z register

		ret					; End a function with RET

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;		result.
;-----------------------------------------------------------
SUB16:
		; Load beginning address of first operand into X
		ldi		XL, low(SUB16_OP1)	; Load low byte of address
		ldi		XH, high(SUB16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP2)	; Load low byte of address
		ldi		YH, high(SUB16_OP2)	; Load high byte of address

		; Load beginning address of result into Z

		ldi		ZH, HIGH(SUB16_Result) ; Load high byte of address
		ldi		ZL, LOW(SUB16_Result)  ; Load low byte of address

		ld		R16, X+				; load R16 from operand 1
		ld		R17, X				; load R17 from operand 1
		ld		R18, Y+				; load R18 from operand 2
		ld		r19, Y				; load R19 from operand 2

		; Execute the function

		sub		R16, R18			; Sub registers
		st		Z+, R16				; Store R16 into Z with post increment

		sbc		R17, R19			; Sub registers with carry
		st		Z+, R17				; Store R17 into Z with post increment

		ret							; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;		result.
;-----------------------------------------------------------
MUL24:
		; Load beginning address of first operand into X
		ldi		XL, low(MUL24_OP1)	; Load low byte of address
		ldi		XH, high(MUL24_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(MUL24_OP2)	; Load low byte of address
		ldi		YH, high(MUL24_OP2)	; Load high byte of address

		; Load beginning address of result into Z

		ldi		ZH, HIGH(MUL24_Result)
		ldi		ZL, LOW(MUL24_Result)

		; Execute the function

		; Set multiplier in register

		; R21 most significant byte of result, R16 is least

		ldi		R23, 24		; Load counter into R23

		ld		R16, Y+		; Load Y into R16 with post increment
		ld		R17, Y+		; Load Y into R17 with post increment
		ld		R18, Y+		; Load Y into R18 with post increment
		clr		R19			; Clear register R19
		clr		R20			; Clear register R20
		clr		R21			; Clear register R21

MULTLOOP:
		ror		R21			; Rotate register R21
		ror		R20			; Rotate register R20
		ror		R19			; Rotate register R19
		ror		R18			; Rotate register R18
		ror		R17			; Rotate register R17
		ror		R16			; Rotate register R16

		BRCC	MULTSKIP	; Branch if carry cleared

		ld		R22, X+		; Load R22 from register X with post increment
		add		R19, R22	; Add R22 and R19
		ld		R22, X+		; Load R22 from register X with post increment
		adc		R20, R22	; Add R20 and R22 with carry
		ld		R22, X+		; Load R22 from register X with post increment
		adc		R21, R22	; Add R21 and R22 with carry

		ldi		XL, low(MUL24_OP1)	; Load low byte of address
		ldi		XH, high(MUL24_OP1)	; Load high byte of address

MULTSKIP:
		dec		R23			; Decrement R23
		BRNE	MULTLOOP	; Branch if counter equals 0

		ror		R21			; Rotate register R21
		ror		R20			; Rotate register R20
		ror		R19			; Rotate register R19
		ror		R18			; Rotate register R18
		ror		R17			; Rotate register R17
		ror		R16			; Rotate register R16

		st		Z+, R16		; Store R16 into result with post increment
		st		Z+, R17		; Store R16 into result with post increment
		st		Z+, R18		; Store R16 into result with post increment
		st		Z+, R19		; Store R16 into result with post increment
		st		Z+, R20		; Store R16 into result with post increment
		st		Z+, R21		; Store R16 into result with post increment

		ret					; End a function with RET

;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((D - E) + F)^2
;		by making use of SUB16, ADD16, and MUL24.
;
;		D, E, and F are declared in program memory, and must
;		be moved into data memory for use as input operands.
;
;		All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:
		; Setup SUB16 with operands D and E
		; Perform subtraction to calculate D - E

		ldi		ZH, HIGH(COMP_OP1)		; Load high byte of operand D into Z register
		ldi		ZL, LOW(COMP_OP1)		; Load low byte of operand D into Z register

		ld		R16, Z+					; Load R16 from operand D
		ld		R17, Z					; Load R17 from operand D

		ldi		ZH, HIGH(SUB16_OP1)		; Load high byte of sub operand 1 into Z register
		ldi		ZL, LOW(SUB16_OP1)		; Load low byte of sub operand 1 into Z register

		st		Z+, R16					; Store R16 into sub operand 1
		st		Z, R17					; Store R17 into sub operand 1

		ldi		ZH, HIGH(COMP_OP2)		; Load high byte of operand E into Z register
		ldi		ZL, LOW(COMP_OP2)		; Load low byte of operand E into Z register

		ld		R16, Z+					; Load R16 from operand E
		ld		R17, Z					; Load R17 from operand E

		ldi		ZH, HIGH(SUB16_OP2)		; Load high byte of sub operand 2 into Z register
		ldi		ZL, LOW(SUB16_OP2)		; Load low byte of sub operand 2 into Z register

		st		Z+, R16					; Store R16 into sub operand 1
		st		Z, R17					; Store R17 into sub operand 1

		RCALL	SUB16					; Add SUB16 function

		; Setup the ADD16 function with SUB16 result and operand F
		; Perform addition next to calculate (D - E) + F

		ldi		ZH, HIGH(SUB16_Result)	; Load high byte of sub result into Z register
		ldi		ZL, LOW(SUB16_Result)	; Load low byte of sub result into Z register

		ld		R16, Z+					; Load R16 from sub result
		ld		R17, Z					; Load R17 from sub result

		ldi		ZH, HIGH(ADD16_OP1)		; Load high byte of add operand 1 into Z register
		ldi		ZL, LOW(ADD16_OP1)		; Load low byte of add operand 1 into Z register

		st		Z+, R16					; Store R16 into add operand 1
		st		Z, R17					; Store R17 into add operand 1

		ldi		ZH, HIGH(COMP_OP3)		; Load high byte of operand F into Z register
		ldi		ZL, LOW(COMP_OP3)		; Load low byte of operand F into Z register

		ld		R16, Z+					; Load R16 from operand F
		ld		R17, Z					; Load R17 from operand F

		ldi		ZH, HIGH(ADD16_OP2)		; Load high byte of add operand 2 into Z register
		ldi		ZL, LOW(ADD16_OP2)		; Load low byte of add operand 2 into Z register

		st		Z+, R16					; Store R16 into sub operand 1
		st		Z, R17					; Store R17 into sub operand 1

		RCALL	ADD16					; Call ADD16 Function

		; Setup the MUL24 function with ADD16 result as both operands
		; Perform multiplication to calculate ((D - E) + F)^2

		ldi		ZH, HIGH(ADD16_Result)	; Load high byte of add result into Z register
		ldi		ZL, LOW(ADD16_Result)	; Load low byte of add result into Z register

		ld		R16, Z+					; Load R16 from add result
		ld		R17, Z+					; Load R17 from add result
		ld		R18, Z					; Load R18 from add result
										
		ldi		ZH, HIGH(MUL24_OP1)		; Load high byte of mul operand 1 into Z register
		ldi		ZL, LOW(MUL24_OP1)		; Load low byte of mul operand 1 into Z register
										
		st		Z+, R16					; Store R16 into mul operand 1
		st		Z+, R17					; Store R17 into mul operand 1
		st		Z,  R18					; Store R18 into mul operand 1
										
		ldi		ZH, HIGH(MUL24_OP2)		; Load high byte of mul operand 1 into Z register
		ldi		ZL, LOW(MUL24_OP2)		; Load low byte of mul operand 1 into Z register
										
		st		Z+, R16					; Store R16 into mul operand 2
		st		Z+, R17					; Store R17 into mul operand 2
		st		Z,	R18					; Store R18 into mul operand 2

		RCALL	MUL24					; Call MUL24 Function

		ldi		ZH, HIGH(MUL24_Result)	; Load high byte of mul operand 1 into Z register
		ldi		ZL, LOW(MUL24_Result)	; Load low byte of mul operand 1 into Z register

		ld		R16, Z+					; Load R16 from add result
		ld		R17, Z+					; Load R17 from add result
		ld		R18, Z+					; Load R18 from add result
		ld		R19, Z+					; Load R16 from add result
		ld		R20, Z+					; Load R17 from add result
		ld		R21, Z					; Load R18 from add result

		ldi		ZH, HIGH(COMP_Result)	; Load high byte of mul operand 1 into Z register
		ldi		ZL, LOW(COMP_Result)	; Load low byte of mul operand 1 into Z register

		st		Z+, R16					; Store R16 into mul operand 2
		st		Z+, R17					; Store R17 into mul operand 2
		st		Z+,	R18					; Store R18 into mul operand 2
		st		Z+, R19					; Store R16 into mul operand 2
		st		Z+, R20					; Store R17 into mul operand 2
		st		Z,	R21					; Store R18 into mul operand 2

		ret								; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;			A - Operand A is gathered from address $0101:$0100
;			B - Operand B is gathered from address $0103:$0102
;			Res - Result is stored in address 
;					$0107:$0106:$0105:$0104
;		You will need to make sure that Res is cleared before
;		calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to beginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret					; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

; ADD16 operands
AddOp1:						
	.DW 0xA2FF				; Add operand 1
AddOp2:						
	.DW 0xF477				; Add operand 2

; SUB16 operands
SubOp1:						
	.DW 0xF08A				; Sub operand 1
SubOp2:						
	.DW 0x4BCD				; Sub operand 2

; MUL24 operands
MulOp1:						
	.DB 0xFF, 0xFF, 0xFF	; Mul operand 1 stored in little endian
MulOp2:						
	.DB 0xFF, 0xFF, 0xFF	; Mul operand 2 stored in little endian

; Compound operands
OperandD:
	.DW	0xFD51				; test value for operand D
OperandE:
	.DW	0x1EFF				; test value for operand E
OperandF:
	.DW	0xFFFF				; test value for operand F

;***********************************************************
;*	Data Memory Allocation
;***********************************************************

.dseg
.org	$0100				; data memory allocation for MUL16 example
addrA:	.byte 2
addrB:	.byte 2
LAddrP:	.byte 4

; Below is an example of data memory allocation for ADD16.
; Consider using something similar for SUB16 and MUL24.

.org	$0110				; data memory allocation for operands
ADD16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
ADD16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16

.org	$0120				; data memory allocation for results
ADD16_Result:
		.byte 3				; allocate three bytes for ADD16 result

.org	$0130				; data memory allocation for operands
SUB16_OP1:
		.byte 2				; allocate two bytes for first operand of SUB16
SUB16_OP2:
		.byte 2				; allocate two bytes for second operand of SUB16

.org	$0140				; data memory allocation for results
SUB16_Result:
		.byte 2				; allocate two bytes for SUB16 result

.org	$0150				; data memory allocation for operands
MUL24_OP1:
		.byte 3				; allocate three bytes for first operand of MUL24
MUL24_OP2:
		.byte 3				; allocate three bytes for second operand of MUL24

.org	$0160				; data memory allocation for results
MUL24_Result:
		.byte 6				; allocate six bytes for MUL24 result

.org	$0170				; data memory allocation for operands
COMP_OP1:
		.byte 2				; allocate three bytes for first operand of COMP
COMP_OP2:
		.byte 2				; allocate three bytes for second operand of COMP
COMP_OP3:
		.byte 2				; allocate three bytes for third operand of COMP

.org	$0180				; data memory allocation for results
COMP_Result:
		.byte 6				; allocate six bytes for MUL24 result

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program