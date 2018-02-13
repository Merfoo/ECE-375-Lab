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
    CPI   YL, $10  ; Compare current LCD data address with last address of 1st line for LCD
    BRNE  BEGLOOP  ; Only write character data to data address for  1st line for LCD

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
    
    CALL    LCDWrite

END:  
    rjmp    END     ; jump back to end and create an infinite
                    ; while loop.  Generally, every main program is an
                    ; infinite while loop, never let the main program
                    ; just run off

;***********************************************************
;*    Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;        beginning of your functions
;-----------------------------------------------------------
FUNC:           ; Begin a function with a label
                ; Save variables by pushing them to the stack

                ; Execute the function here
                
                ; Restore variables by popping them from the stack,
                ; in reverse order

        ret     ; End a function with RET

;***********************************************************
;*    Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:
.DB        "Fauzi and Aidan!"        ; Declaring data in ProgMem
STRING_END:
.DB        "This is assembly"

;***********************************************************
;*    Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"        ; Include the LCD Driver
*/