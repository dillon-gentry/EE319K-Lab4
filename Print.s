; Print.s
; Student names: change this to your names or look very silly
; Last modification date: change this to the last modification date or look very silly
; Runs on LM4F120 or TM4C123
; EE319K lab 7 device driver for any LCD
;
; As part of Lab 7, students need to implement these LCD_OutDec and LCD_OutFix
; This driver assumes two low-level LCD functions
; ST7735_OutChar   outputs a single 8-bit ASCII character
; ST7735_OutString outputs a null-terminated string 

remainder                 EQU   0
	
    IMPORT   ST7735_OutChar
    IMPORT   ST7735_OutString
    EXPORT   LCD_OutDec
    EXPORT   LCD_OutFix

    AREA    |.text|, CODE, READONLY, ALIGN=2
    THUMB

;-----------------------LCD_OutDec-----------------------
; Output a 32-bit number in unsigned decimal format
; Input: R0 (call by value) 32-bit unsigned number
; Output: none
; Invariables: This function must not permanently modify registers R4 to R11
LCD_OutDec
	PUSH{R2, R3, R4, LR}
	  SUB SP, #8
	  
      CMP R0, #10
	  BLO Print
	 
	  MOV R3, #10
	  UDIV R1, R0, R3    ;this is for MOD
	  MUL R2, R1, R3
	  SUB R2, R0, R2      ;MOD is in R2
	  
	  STR R2, [SP]				;Stores modulus value onto the stack pointer.
	  MOV R0, R1					;Puts the input back into R0.
	  BL LCD_OutDec
	  LDR R0, [SP, #remainder]		;Loads the value of R0, from the stack.
	
Print
	  ADD R0, R0, #0x30			
	  BL ST7735_OutChar			
	  ADD SP, #8
	  POP {R2, R3, R4, PC}

      BX  LR
;* * * * * * * * End of LCD_OutDec * * * * * * * *

; -----------------------LCD _OutFix----------------------
; Output characters to LCD display in fixed-point format
; unsigned decimal, resolution 0.001, range 0.000 to 9.999
; Inputs:  R0 is an unsigned 32-bit number
; Outputs: none
; E.g., R0=0,    then output "0.000 "
;       R0=3,    then output "0.003 "
;       R0=89,   then output "0.089 "
;       R0=123,  then output "0.123 "
;       R0=9999, then output "9.999 "
;       R0>9999, then output "*.*** "
; Invariables: This function must not permanently modify registers R4 to R11
LCD_OutFix
    PUSH{R4, LR}
	
	MOV R1, #9999			;will check to see if value exceeds resolution
	CMP R0, R1
	BHI astrid
	
	MOV R1, #999			;will check to see if value requires something other than zero before decimal point
	CMP R0, R1
	BGT Decimal
	
	MOV R4, R0				
	MOV R0, #0x30			;prints leading zero
	BL ST7735_OutChar
    MOV R0, #0x2E			;prints decimal pt
	BL ST7735_OutChar
check						;this chunk is used as a way to tell how many
	MOV R3, #100			;zeroes will be included in the chunk of digits
	UDIV R3, R4, R3			;following the decimal point
	CMP R3, #0
    BEQ onezero
	MOV R0, R4
	BL LCD_OutDec
	B done
	
onezero 					;this section will print a zero in the hundreds place
	MOV R0, #0x30
	BL ST7735_OutChar
	MOV R3, #10
	UDIV R3, R4, R3
	CMP R3, #0				;checks to see if zero is needed in tens place
    BEQ twozero
	MOV R0, R4
	BL LCD_OutDec
	B done
	
twozero						;this section will print a zero in the hundreds and tens place
    MOV R0, #0x30
	BL ST7735_OutChar
	MOV R0, R4
	BL LCD_OutDec 
	B done
	
Decimal						;adjusts value for inputs higher than 999 but less than 10,000
    MOV R4, R0
    MOV R1, #1000
	UDIV R2,R0,R1
	MOV R3, R2
	ADD R0, R2, #0x30
    BL ST7735_OutChar
    MOV R0, #0x2E	
	BL ST7735_OutChar
	
	
	MOV R1, #1000			;Adjusts input to isolate digits after decimal pt
	UDIV R2,R4,R1
	MUL R2,R2,R1
	SUBS R4,R4,R2			;R4 is 0XXX
	B check					;sends 0XXX to code where XXX is displayed to screen
    
astrid							;will print all asterisks for values greater than 9999
	MOV R0, #0x2A				
	BL ST7735_OutChar
	MOV R0, #0x2E	
	BL ST7735_OutChar
    MOV R0, #0x2A
	BL ST7735_OutChar
	MOV R0, #0x2A
	BL ST7735_OutChar
	MOV R0, #0x2A
	BL ST7735_OutChar

done
	 POP {R4, PC}
     BX   LR
 
     
;* * * * * * * * End of LCD_OutFix * * * * * * * *

     ALIGN                           ; make sure the end of this section is aligned
     END                             ; end of file
