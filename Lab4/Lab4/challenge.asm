/*;***********************************************************
;*
;*    main.asm
;*
;*    Displays text to LCD screen
;*
;*    This is the skeleton file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*     Author: Fauzi Kliman, Aidan Carson
;*       Date: 1/30/18
;*
;***********************************************************

.include "m128def.inc"  ; Include definition file

;***********************************************************
;*    Internal Register Definitions and Constants
;***********************************************************
.def    mpr = r16       ; Multipurpose register is
                        ; required for LCD Driver

;***********************************************************
;*    Start of Code Segment
;***********************************************************
.cseg                   ; Beginning of code segment

;***********************************************************
;*    Interrupt Vectors
;***********************************************************
.org    $0000           ; Beginning of IVs
        rjmp INIT       ; Reset interrupt

.org    $0046           ; End of Interrupt Vectors

;***********************************************************
;*    Program Initialization
;***********************************************************
INIT:   ; The initialization routine
    ; Initialize Stack Pointer
    LDI    mpr, LOW(RAMEND)    ; Load low byte of end SRAM address into mpr
    OUT    SPL, mpr            ; Write byte to SPL
    LDI    mpr, HIGH(RAMEND)   ; Load high byte of end SRAM address into mpr
    OUT    SPH, mpr            ; Write byte to SPL

    ; Initialize LCD Display
    CALL   LCDInit

    ; NOTE that there is no RET or RJMP from INIT, this
    ; is because the next instruction executed is the
    ; first instruction of the main program

;***********************************************************
;*    Main Program
;***********************************************************
MAIN:               ; The Main program
    ; Move strings from Program Memory to Data Memory
    ; First names
    ; Init Z to beg string array
    LDI   ZL, LOW(STRING_BEG << 1)  ; Load low byte address portion of first element to Z
    LDI   ZH, HIGH(STRING_BEG << 1) ; Load high byte address portion of first element to Z

    ; Init Y to destination character for 1st line for LCD
    LDI   YL, $00  ; Load low byte address portion of where the LCD will read the character data
    LDI   YH, $01  ; Load high byte address portion of where the LCD will read the character data

    ; Loop over character array, writing to address specified by LCD for 1st line
BEGLOOP:
    LPM   mpr, Z+  ; Load character data from program memory into reg 16 and inc Z address
    ST    Y+, mpr  ; Store character data from reg 16 into data memory and inc Y address
    CPI   ZL, LOW(STRING_END << 1)	; Compare current LCD data address with last address of 1st line for LCD
    BRLT  BEGLOOP  ; Only write character data to data address for  1st line for LCD

    ; Move strings from Program Memory to Data Memory
    ; Hello World
    ; Init Z to beg string array
    LDI   ZL, LOW(STRING_END << 1)    ; Load low byte address portion of first element to Z
    LDI   ZH, HIGH(STRING_END << 1)   ; Load high byte address portion of first element to Z

    ; Init Y to destination character for 2nd line for LCD
    LDI   YL, $10  ; Load low byte address portion of where the LCD will read the character data
    LDI   YH, $01  ; Load high byte address portion of where the LCD will read the character data

    ; Loop over character array, writing to address specified by LCD for 2nd line
HELLOLOOP:
    LPM   mpr, Z+   ; Load character data from program memory into reg 16 and inc Z address
    ST    Y+, mpr   ; Store character data from reg 16 into data memory and inc Y address
    CPI   YL, $20   ; Compare current LCD data address with last address of 2nd line for LCD
    BRNE  HELLOLOOP ; Only write character data to data address for  2nd line for LCD


	LDI		ZL, $1F	; Init Z to point to the last character cell on the LCD
	LDI		ZH, $01	; Init Z to point to the last character cell on the LCD
	MOVW	Y, Z	; Set Y to point to the same character cell as Z
	DEC		ZL		; Decrement Z to point to the character cell before Y

	; Display the strings, moving the strings to the right after a delay
DISPLAY:
	CALL	LCDWrite	; Display the strings to the LCD
	CALL	FUNC		; Wait some time
	LD		R17, Y		; Load the last character into a temp register

	; Move the strings right 1 character cell on the LCD
ROTATE:  
	LD		R16, Z		; Load the character before Y into a temp register
	ST		Y, R16		; Load the character before Y from temp register into Y
	DEC		YL			; Decrement Y to point to previous character cell
	DEC		ZL			; Decrement Z to point to previous character cell
	CPI		YL, $01		; Compare Y to the 2nd character cell
	BRGE	SKIPY		; Go to beginning of the ROTATE loop if greater than 1st character cell
	ST		Y, R17		; Load the character in the very last character cell from temp register into first
	LDI		YL, $1F		; Set Y to point to the last character cell
	LDI		ZL, $1E		; Set Z to point to the character cell before Y
	JMP		DISPLAY		; Jump to DISPLAY to upate the LCD

SKIPY:
    rjmp    ROTATE     ; jump back to DISPLAY and create an infinite
                    ; while loop.  Generally, every main program is an
                    ; infinite while loop, never let the main program
                    ; just run off

;***********************************************************
;*    Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Has busy loops to "wait"
; Desc: "Waits" some time by having busy loops before finishing
;-----------------------------------------------------------
FUNC:           ; Begin a function with a label
                ; Save variables by pushing them to the stack

                ; Execute the function here
		PUSH	R17		; Save R17 onto stack
		PUSH	R18		; Save R18 onto stack
		PUSH	R19		; Save R19 onto stack

		LDI		R17, 0	; Init R17 to 0
		LDI		R18, 0	; Init R18 to 0
		LDI		R19, 0	; Init R19 to 0

WAITY:
		INC		R17			; Increment R17
		CPI		R17, 255	; Compare R17 to 255
		BRNE	WAITY		; Jump to beginning of loop if not 255
		INC		R18			; Increment R18
		LDI		R17, 0		; Reset R17 to 0
		CPI		R18, 255	; Compare R18 to 255
		BRNE	WAITY		; Jump to beginning of loop if not 255
		INC		R19			; Increment R19
		LDI		R17, 0		; Reset R17 to 0
		LDI		R18, 0		; Reset R18 to 0
		CPI		R19, 25		; Compare R19 to 25
		BRNE	WAITY		; Jump to beginning of loop if not 255

		POP		R19		; Restore R19 from stack
		POP		R18		; Restore R18 from stack
		POP		R17		; Restore R17 from stack

        ret     ; End a function with RET

;***********************************************************
;*    Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:
.DB        " Fauzi and Aidan"        ; Declaring data in ProgMem
STRING_END:
.DB        " did dachallenge"

;***********************************************************
;*    Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"        ; Include the LCD Driver
*/