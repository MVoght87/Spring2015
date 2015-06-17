*-----------------------------------------------------------
* Title      : 68K-Disassembler
* Written by : Michael Voght, Joel Richart, Allon Kim
* Date       : 6/05/15
* Description: The user may store an EASY68K program into the 
*               memory of this program. The user then gives a 
*               starting address and ending address, the
*               Disassembler will read the data in memory from a 
*               memory location and convert the data into valid
*               opcodes. 
*               ASSUMPTION: The user cannot have the origin of
*               their loaded program at or less than $3000.
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
                    
MAIN                BSR     INIT_DATA
                    BSR     GET_INPUT
                    BSR     INIT_DATA
                    BSR     CONFIRM_INPUT
                    BSR     INIT_DATA
                    BSR     DISASSEMBLE
                    BSR     PLAY_AGAIN
                    BRA     MAIN
*-----------------------------------------------------------
*---------------------SUB-ROUTINES--------------------------
*-----------------------------------------------------------

************************************************************
*INIT_DATA: Sets all the data registers to 0
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: D0 - D7 all equal 0
************************************************************

INIT_DATA           CLR.L   D0                      ; Reset registers
                    CLR.L   D1
                    CLR.L   D2
                    CLR.L   D3
                    CLR.L   D4
                    CLR.L   D5
                    CLR.L   D6
                    CLR.L   D7
                    RTS

************************************************************
*GET_INPUT: Gets the users starting address and ending address
*               of the data they would like disassembled
*PRE-CONDITIONS: Data registers are cleared, and users code
*               has an origin above 3000
*POST-CONDITIONS: Starting and Ending address are stored
************************************************************

GET_INPUT           LEA     START_PRINT, A1         ; Ask for Starting Address
                    BSR     PRINT_MESSAGE
                
                    BSR     USER_INPUT_STR          ; Read Starting Address
                    CMP.B   #8, D1
                    BGT     INVALID_INPUT           ; Address must be long length
                    MOVEA.L A1, A2                  ; Copy Input
                    BSR     CONVERT_STR
                    CMP.B   #1, D0                  ; Check for bad hex value
                    BEQ     INVALID_INPUT
                    CMP.L   #$3002, D3              ; Input can't be less than 3000
                    BCS     INVALID_INPUT
                    MOVE.L  D3, START_ADD           ; Store if good

                    BSR     INIT_DATA               ; Clear registers
                    LEA     END_PRINT, A1           ; Ask for Ending Addrress
                    BSR     PRINT_MESSAGE
                
                    BSR     USER_INPUT_STR          ; Read Ending Address
                    CMP.B   #8, D1
                    BGT     INVALID_INPUT
                    MOVEA.L A1, A2
                    BSR     CONVERT_STR
                    CMP.B   #1, D0
                    BEQ     INVALID_INPUT
                    MOVE.L  D3, END_ADD
                    RTS

INVALID_INPUT       LEA     BAD_INPUT, A1           ; Tell user if bad address given
                    BSR     PRINT_MESSAGE
                    BRA     MAIN                    ; Start over

************************************************************
*CONFIRM_INPUT: Displays the address the user gave, and confirms
*               if that is the address the user would like to
*               disassemble
*PRE-CONDITIONS: The starting address and ending address are 
*               stored
*POST-CONDITIONS: If Y or y is given by the user the program
*               continues, if not then the program will ask
*               for the users starting and ending address
************************************************************
                
CONFIRM_INPUT       LEA     CONFIRM_START, A1       ; Show Starting Address
                    BSR     PRINT_MESSAGE
                    LEA     START_ADD, A6
                    MOVE.L  #3, D3
                    LEA     BUFFER, A1
                    BSR     GRAB_DATA               ; Print given address
                    MOVE.B  #$0, (A1)+
                    BSR     PRINT_BUFFER
                    
                    LEA     CONFIRM_END, A1         ; Show Ending Address
                    BSR     PRINT_MESSAGE
                    LEA     END_ADD, A6
                    MOVE.L  #3, D3
                    LEA     BUFFER, A1
                    BSR     GRAB_DATA               ; print given address
                    MOVE.B  #$0, (A1)+
                    BSR     PRINT_BUFFER
                    
                    LEA     CONFIRM_MESSAGE, A1     ; Ask user to confirm addresses
                    BSR     PRINT_MESSAGE
                    MOVE.B  #5, D0
                    TRAP    #15
                    LEA     NEW_LINE, A1
                    BSR     PRINT_MESSAGE
                    CMP.L   #$59, D1                ; If Y continue, if not Y start over
                    BEQ     GOOD_INPUT
                    CMP.L   #$79, D1                ; y is acceptable
                    BEQ     GOOD_INPUT
                    BRA     MAIN
GOOD_INPUT          RTS

************************************************************
*GRAB_DATA: Given values stored in A6, those values are converted
*               to ASCII Hex values, so they can be displayed
*               to the console appropriately.
*PRE-CONDITIONS: D3 must contained 0 for byte length, 1 for 
*               word length and 3 for long length.
*POST-CONDITIONS: converts the value stored in A6 into ASCII
*               hex and is then added to A1 to be handled
************************************************************

GRAB_DATA           MOVE.B  (A6)+, D1               ; grab byte of address
                    BSR     CONVERT_TO_HEX
                    SUB.B   #1, D3                  ; D3 holds address length
                    BGE     GRAB_DATA               ; display address in bytes
                    RTS 

CONVERT_TO_HEX      MOVE.B  D1, D2                  ; Copy for second nibble
                    AND.B   #$F0, D1                ; Mask first nibble
                    LSR.B   #4, D1                  ; bring nibble to front
                    CMP.B   #10, D1                 ; If 10 or greater, it's a letter
                    BGE     MSB_LETTER
                    ADD.B   #$30, D1                ; if not letter then decimal + #$30 = value in hex  
MSB                 MOVE.B  D1, (A1)+
                    AND.B   #$0F, D2                ; Mask second nibble
                    CMP.B   #10, D2
                    BGE     LSB_LETTER
                    ADD.B   #$30, D2
LSB                 MOVE.B  D2, (A1)+
                    BRA     DONE_PRINT
                
MSB_LETTER          ADD.B   #$37, D1                ; Letter in decimal + #$37 = letter in hex
                    BRA     MSB

LSB_LETTER          ADD.B   #$37, D2
                    BRA     LSB                

DONE_PRINT          RTS

************************************************************
*CONVERT_STR: Given a string of decimal values, the string is
*               converted to ASCII Hex
*PRE-CONDITIONS: D0 is cleared and D1 contains the string length
*POST-CONDITIONS: Converts a string of decimal values to hex
************************************************************

CONVERT_STR         BSR     STR_TO_HEX
                    CMP.B   #1, D0                  ; D0 holds flag for bad hex 
                    BEQ     RETURN
                    SUB.B   #1, D1                  ; Iterator stops when string is empty
                    BNE     CONVERT_STR
RETURN              RTS

************************************************************
*STR_TO_HEX: Given a string, determine its decimal value and
*               replace it with it's hex value.
*PRE-CONDITIONS: A2 holds the string to be converted, D0 is empty
*               to catch errors in the string
*POST-CONDITIONS: D3 holds the final conversion
************************************************************
                
STR_TO_HEX          MOVE.B  (A2)+, D2               ; Pointer to value being converted
                    MOVE.B  D1, D7
                    SUB.W   #1, D7
                    MULU    #4, D7                  ; Hex value has 4 binary numbers, position of hex is multiplicative by 4
                
                    CMP.B   #$30,D2                 ; Sets character value depending on HEX value
                    BNE     HEX_ONE
                    MOVE.L  #$0, D2                 ; 0
                    ASL.L   D7, D2                  ; Shift hex to appropriate location
                    ADD.L   D2, D3                  ; D3 will store the final hex value
                    RTS

HEX_ONE             CMP.B   #$31,D2
                    BNE     HEX_TWO
                    MOVE.L  #$1, D2                 ; 1
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
        
HEX_TWO             CMP.B   #$32,D2
                    BNE     HEX_THREE
                    MOVE.L  #$2, D2                 ; 2
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                       
HEX_THREE           CMP.B   #$33,D2
                    BNE     HEX_FOUR
                    MOVE.L  #$3, D2                 ; 3
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_FOUR            CMP.B   #$34,D2
                    BNE     HEX_FIVE
                    MOVE.L  #$4, D2                 ; 4
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_FIVE            CMP.B   #$35,D2
                    BNE     HEX_SIX
                    MOVE.L  #$5, D2                 ; 5
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_SIX             CMP.B   #$36,D2
                    BNE     HEX_SEVEN
                    MOVE.L  #$6, D2                 ; 6
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_SEVEN           CMP.B   #$37,D2
                    BNE     HEX_EIGHT
                    MOVE.L  #$7, D2                 ; 7
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_EIGHT           CMP.B   #$38,D2
                    BNE     HEX_NINE
                    MOVE.L  #$8, D2                 ; 8
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_NINE            CMP.B   #$39,D2
                    BNE     HEX_A
                    MOVE.L  #$9, D2                 ; 9
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_A               CMP.B   #$41,D2
                    BNE     HEX_B
                    MOVE.L  #$A, D2                 ; A
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                
HEX_B               CMP.B   #$42,D2
                    BNE     HEX_C
                    MOVE.L  #$B, D2                 ; B
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_C               CMP.B   #$43,D2
                    BNE     HEX_D
                    MOVE.L  #$C, D2                 ; C
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                
HEX_D               CMP.B   #$44,D2
                    BNE     HEX_E
                    MOVE.L  #$D, D2                 ; D
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_E               CMP.B   #$45,D2
                    BNE     HEX_F
                    MOVE.L  #$E, D2                 ; E
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                        
HEX_F               CMP.B   #$46,D2
                    BNE     HEX_INVALID
                    MOVE.L  #$F, D2                 ; F
                    ASL.L   D7, D2
                    ADD.L   D2, D3
                    RTS
                
HEX_INVALID         MOVE.B  #1, D0
                    RTS

************************************************************
*DISASSEMBLE: Reads a byte from memory, known as an OPCODE,
*               prints the address that the OPCODE was read
*               from and then determines the OPCODE through
*               CYPHER_OPCODE. Also handles how many OPCODES
*               can be printed to a screen.
*PRE-CONDITIONS: Starting address and ending address are
*               stored in START_ADD and END_ADD. Memory
*               should also contain a valid OPCODE or it will
*               print out bad data.
*POST-CONDITIONS: Grabs and shares memory contents at given 
*               address and repeats until finished. Only a 
*               page of contents is displayed at a time.
************************************************************

DISASSEMBLE         MOVE.L  (START_ADD), A0         ; load starting address into pointer
                    LEA     END_ADD, A3             ; Iteration ends at ending address
                    MOVE.L  (A3), D0
                    MOVE.B  #25, D7                 ; Page controller (25 lines displayed at a time)
DIS_LOOP            LEA     BUFFER, A1
                    CMP.L   A0, D0                  ; If starting address is less then end address keep going
                    BLE     DIS_DONE
                    BSR     PRINT_ADDRESS
                    MOVE.W  (A0)+, D1               ; grab OPCODE
                    MOVEM.W D0/D7, -(SP)            ; D0 and D7 are saved so they can be used in Cyper Opcode
                    BSR     CYPHER_OPCODE
                    MOVEM.W (SP)+, D0/D7            ; return values back D0 and D7
                    SUB.B   #1, D7                  ; subtract 1 from iterator due to 1 line of OPCODE being written
                    BEQ     MAX_PAGE
                    BRA     DIS_LOOP                ; Repeat until at ending address
                
DIS_DONE            RTS

MAX_PAGE            MOVEM.W D0, -(SP)               ; D0 is saved to be used in user_input_str
                    LEA     CONTINUE, A1
                    BSR     PRINT_MESSAGE
                    BSR     USER_INPUT_STR
                    MOVEM.W (SP)+, D0               ; return value back to D0
                    MOVE.B  #30, D7                 ; iterator for 30 lines perpage is set
                    BRA     DIS_LOOP
                
************************************************************
*CYPHER_OPCODE: Given an OPCODE determines and displays the
*               OPCODE to the Console
*PRE-CONDITIONS: D1 contains the Hex OPCODE to be disassembled
*POST-CONDITIONS: OPCODE is disassembled and appropriately
*               display to the console.
************************************************************

CYPHER_OPCODE       BSR     GRAB_FIRST_HEX
                    
                    CMP.B   #$0, D2
                    BEQ     FIRST_HEX_IS_0
                    
                    CMP.B   #$3, D2                 ; 0 condition has already been checked, so 1-3 is move
                    BLE     OPCODE_MOVE_GROUP
                    
                    CMP.B   #$4, D2
                    BEQ     FIRST_HEX_IS_4
                    
                    CMP.B   #$5, D2
                    BEQ     OPCODE_SUBQ
                    
                    CMP.B   #$6, D2
                    BEQ     FIRST_HEX_IS_6
                    
                    CMP.B   #$8, D2
                    BEQ     FIRST_HEX_IS_8
                    
                    CMP.B   #$9, D2
                    BEQ     OPCODE_SUB
                    
                    CMP.B   #$B, D2
                    BEQ     FIRST_HEX_IS_B
                    
                    CMP.B   #$C, D2
                    BEQ     OPCODE_MULS
                    
                    CMP.B   #$D, D2
                    BEQ     FIRST_HEX_IS_D
                    
                    CMP.B   #$E, D2
                    BEQ     FIRST_HEX_IS_E
                    
                    BRA     INVALID_OPCODE

*-----------------------------------------------------------
FIRST_HEX_IS_0      BSR     GRAB_SECOND_HEX

                    MOVE.B  D2, D3              ; Make copy of 2nd Hex Value
                    AND.B   #$1, D3             ; Check if odd
                    BNE     OPCODE_BCLR         ; If odd then OPCODE is BCLR
                    CMP.B   #$0, D2
                    BEQ     OPCODE_ORI          ; If 0 then OPCODE is ORI
                    CMP.B   #$C, D2
                    BEQ     OPCODE_CMPI         ; If C then OPCODE is CMPI
                    BRA     INVALID_OPCODE

*-----------------------------------------------------------
FIRST_HEX_IS_4      BSR     GRAB_SECOND_HEX
                
                    MOVE.B  D2, D3
                    AND.B   #$1, D3             
                    BNE     OPCODE_LEA          ; If odd then OPCODE is LEA
                    CMP.B   #$4, D2
                    BEQ     OPCODE_NEG          ; If 4 then OPCODE is NEG
                    CMP.B   #$8, D2
                    BEQ     OPCODE_MOVEM
                    CMP.B   #$C, D2
                    BEQ     OPCODE_MOVEM        ; If 8 || C then OPCODE is MOVEM
                    CMP.B   #$E, D2
                    BEQ     OPCODE_RTS_JSR      ; If E then OPCODE is JSR or RTS
                    BRA     INVALID_OPCODE      ; If not Odd, 4, 8, C, or E then bad Hex

*-----------------------------------------------------------
FIRST_HEX_IS_6      BSR     GRAB_SECOND_HEX

                    CMP.B   #$0, D2
                    BEQ     OPCODE_BRA
                    CMP.B   #$5, D2
                    BEQ     OPCODE_BCS
                    CMP.B   #$8, D2
                    BEQ     OPCODE_BVC
                    CMP.B   #$C, D2
                    BEQ     OPCODE_BGE
                    CMP.B   #$D, D2
                    BEQ     OPCODE_BLT
                    BRA     INVALID_OPCODE

*-----------------------------------------------------------
FIRST_HEX_IS_8      BSR     GRAB_SECOND_HEX
                    BRA     OPCODE_DIVS_OR

*-----------------------------------------------------------
FIRST_HEX_IS_B      BSR     GRAB_SECOND_HEX

                    MOVE.B  D2, D3
                    AND.B   #$1, D3
                    BNE     OPCODE_EOR          ; If odd then OPCODE is EOR
                    BRA     OPCODE_CMP          ; If even then OPCODE is CMP

*-----------------------------------------------------------
FIRST_HEX_IS_D      BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP

                    CMP.B   #$3, D5
                    BEQ     OPCODE_ADDA
                    CMP.B   #$7, D5
                    BEQ     OPCODE_ADDA         ; If first opmode is 3 or 7 then it's not ADD
                    BRA     OPCODE_ADD
                    
*-----------------------------------------------------------
FIRST_HEX_IS_E      BSR     GRAB_SECOND_HEX

                    MOVE.B  D2, D3
                    AND.B   #$1, D3
                    BEQ     OPCODE_LSR_ASR_ROR  ; If second hex is even then shift right
                    BRA     OPCODE_LSL_ASL_ROL  ; If odd then shift left

*-----------------------------------------------------------        
OPCODE_MOVE_GROUP   BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA
                    
                    CMP.B   #$1, D5             ; If second octal is 1 then it's MOVEA, else MOVE
                    BEQ     OPCODE_MOVEA
                    BRA     OPCODE_MOVE

*-----------------------------------------------------------        
OPCODE_DIVS_OR      BSR     GRAB_THIRD_HEX

                    CMP.B   #$E, D2
                    BEQ     OPCODE_DIVS
                    CMP.B   #$F, D2
                    BEQ     OPCODE_DIVS
                    CMP.B   #$C, D2
                    BEQ     INVALID_OPCODE
                    CMP.B   #$D, D2
                    BEQ     INVALID_OPCODE

                    CMP.B   #$C, D2
                    BLT     OPCODE_OR                 
                    
*-----------------------------------------------------------
OPCODE_RTS_JSR      CLR.L   D3
                    BSR     GRAB_THIRD_HEX

                    CMP.B   #$7, D2
                    BEQ     OPCODE_RTS
                    BRA     OPCODE_JSR
                    
*-----------------------------------------------------------
OPCODE_LSR_ASR_ROR  BSR     GRAB_MID_BYTE       ; middle byte is masked to store the first and second
                    BSR     GRAB_OP             ; octal value ie. 0000 xxx|x xx00 0000, D4 and D5 respectively
                    BSR     GRAB_LAST_BYTE      ; Last byte is masked to store the third and fourth
                    BSR     GRAB_EA             ; octal value ie. 0000 0000 00xx x|xxx, D6 and D7 respectively
                    
                    CMP.B   #$3, D5             ; if second octal is 3 then it must be EA or INVALID_OPCODE
                    BEQ     CHECK_R_EA
                                        
                    CMP.B   #$1, D6             ; check second octal to determine LSR, ASR, ROR
                    BEQ     OPCODE_LSR
                    CMP.B   #$5, D6
                    BEQ     OPCODE_LSR
                    CMP.B   #$0, D6
                    BEQ     OPCODE_ASR
                    CMP.B   #$4, D6
                    BEQ     OPCODE_ASR
                    CMP.B   #$3, D6
                    BEQ     OPCODE_ROR
                    CMP.B   #$7, D6
                    BEQ     OPCODE_ROR
CHECK_R_EA          CMP.B   #$1, D4             ; check first octal to determine LSR, ASR, ROR
                    BEQ     LOAD_LSR_EA
                    CMP.B   #$0, D4
                    BEQ     LOAD_ASR_EA
                    CMP.B   #$3, D4
                    BEQ     LOAD_ROR_EA
                    BRA     INVALID_OPCODE

*-----------------------------------------------------------
OPCODE_LSL_ASL_ROL  CLR.L   D3

                    BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA
                    
                    CMP.B   #$7, D5             ; if second octal is 7 then it must be EA or INVALID_OPCODE
                    BEQ     CHECK_L_EA
                    
                    CMP.B   #$1, D6
                    BEQ     OPCODE_LSL
                    CMP.B   #$5, D6
                    BEQ     OPCODE_LSL
                    CMP.B   #$0, D6
                    BEQ     OPCODE_ASL
                    CMP.B   #$4, D6
                    BEQ     OPCODE_ASL
                    CMP.B   #$3, D6
                    BEQ     OPCODE_ROL
                    CMP.B   #$7, D6
                    BEQ     OPCODE_ROL
CHECK_L_EA          CMP.B   #$1, D4
                    BEQ     LOAD_LSL_EA
                    CMP.B   #$0, D4
                    BEQ     LOAD_ASL_EA
                    CMP.B   #$3, D4
                    BEQ     LOAD_ROL_EA
                    BRA     INVALID_OPCODE
                    
*-----------------------------------------------------------
*------------------------OP_CODES---------------------------
*-----------------------------------------------------------

**************************BCLR******************************
OPCODE_BCLR         BSR GRAB_THIRD_HEX
                    CMP.B   #$8, D2
                    BLT     INVALID_OPCODE          ; If x < 8 
                    CMP.B   #$C, D2
                    BGE     INVALID_OPCODE          ; If x >= C 

                    BSR     GRAB_MID_BYTE           ; to get Register
                    BSR     GRAB_OP                 ; OP REG stored in D4, OP MODE stored in D5
                    BSR     GRAB_LAST_BYTE          ; last BYTE contains <EA>
                    BSR     GRAB_EA                 ; grab_EA.  D3 = Mode D4 = register
                    BRA     LOAD_BCLR


LOAD_BCLR           BSR     PRINT_BCLR              ; Adds OPCODE name to Buffer
                    BSR     FIND_SIZE               ; Adds size (.B, .W, .L) to Buffer
                    BSR     FIND_EA_MODE            ; Adds EA Mode and Address to Buffer
                    BSR     OPCODE_BREAK            ; Adds ', ' to Buffer
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG            ; Adds source register to Buffer
                    BSR     OPCODE_END              ; Adds Null terminator to Buffer
                    BSR     PRINT_BUFFER            ; Prints the OPCODE command
                    RTS

**************************ORI*******************************
OPCODE_ORI          BSR     GRAB_THIRD_HEX          ; get the third hex and store in D2.
                    CMP.B   #$C, D2                 ; If C or greater, -> invalid
                    BGE     INVALID_OPCODE
                    BSR     GRAB_LAST_BYTE          ; last BYTE contains <EA>
                    BSR     GRAB_EA                 ; grab_EA.  D6 = Mode D7 = register
                    BRA     LOAD_ORI
            
LOAD_ORI            BSR     PRINT_ORI    
                    BSR     FIND_SIZE
                    BSR     PRINT_IMMEDIATE
                    BSR     OPCODE_BREAK
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************CMPI******************************
OPCODE_CMPI         BSR     GRAB_THIRD_HEX          ; get the third hex and store in D2.
                    CMP.B   #$C, D2
                    BGE     INVALID_OPCODE          ; If x >= C
            
                    BSR     GRAB_MID_BYTE           ; to get Register
                    BSR     GRAB_OP                 ; OP REG stored in D4, OP MODE stored in D5
                    BSR     GRAB_LAST_BYTE          ; last BYTE contains <EA>
                    BSR     GRAB_EA                 ;  grab_EA.  D3 = Mode D4 = register
                    BRA     LOAD_CMPI 
 
LOAD_CMPI           BSR     PRINT_CMPI 
                    BSR     FIND_SIZE
                    BSR     PRINT_IMMEDIATE
                    BSR     OPCODE_BREAK
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS


**************************MOVE******************************
OPCODE_MOVE         BSR     GRAB_FIRST_HEX      
                    CMP.B   #$1, D2             ; size subroutine uses second octal, moves size
                    BNE     MOVE_WORD           ; is determined in the first hex value.
                    MOVE.B  #$0, D5             ; If 1 then size is 0 (Byte = 00)
MOVE_WORD           CMP.B   #$3, D2
                    BNE     MOVE_LONG
                    MOVE.B  #$1, D5             ; If 3 then size is 1 (Word = 01)
MOVE_LONG           CMP.B   #$2, D2
                    BNE     LOAD_MOVE
                    MOVE.B  #$2, D5             ; If 2 then size is 2 (Long = 10)
              
LOAD_MOVE           BSR     PRINT_MOVE          ; Load 'MOVE' into buffer
                    BSR     FIND_SIZE           ; Load '.B', '.W', or '.L' into buffer
                    BSR     FIND_EA_MODE        ; Load EA and register/address/literal into buffer
                    BSR     OPCODE_BREAK        ; Load ', ' into buffer
                    BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP
                    CLR.L   D3
                    MOVE.B  #$1, D3             ; Flag to use first and second octals (instead of 
                    BSR     FIND_EA_MODE_DST    ; third and fourth octals to determine EA)
                    BSR     OPCODE_END          ; Add NULL terminator at the end of buffer
                    BSR     PRINT_BUFFER        ; send buffer to console
                    RTS                    

**************************MOVEA*****************************
OPCODE_MOVEA        BSR     GRAB_FIRST_HEX
                    CMP.B   #$1, D2             ; MOVEA can't be BYTE size
                    BEQ     INVALID_OPCODE
                    CMP.B   #$3, D2
                    BNE     MOVEA_LONG
                    MOVE.B  #$1, D5             ; Find_size makes 0 = .B, 1 = .W, and 2 = .L
MOVEA_LONG          CMP.B   #$2, D2
                    BNE     LOAD_MOVEA
                    MOVE.B  #$2, D5
              
LOAD_MOVEA          BSR     PRINT_MOVEA         ; PRINT MOVEA
                    BSR     FIND_SIZE           
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.B  #'A', (A1)+         ; DST must be An
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************MOVEM*****************************
OPCODE_MOVEM        BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA
                    
                    CMP.B   #$0, D6
                    BEQ     INVALID_OPCODE
                    CMP.B   #$1, D6
                    BEQ     INVALID_OPCODE
                    CMP.B   #$5, D6
                    BEQ     INVALID_OPCODE
                    CMP.B   #$6, D6
                    BEQ     INVALID_OPCODE
                    CMP.B   #$3, D6
                    BNE     MOVEM_SIZE
                    CMP.B   #$4, D7
                    BEQ     INVALID_OPCODE
          
MOVEM_SIZE          CMP.B   #$2, D5
                    BNE     MOVEM_LONG
                    MOVE.B  #$1, D5
                    BRA     LOAD_MOVEM
MOVEM_LONG          CMP.B   #$3, D5
                    BNE     INVALID_OPCODE          
                    MOVE.B  #$2, D5
LOAD_MOVEM          CMP.B   #$6, D4
                    BEQ     MEM_TO_REG              ; If first octal is 6 then MOVEM is memory to register
                    BRA     REG_TO_MEM              ; else it's register to memory
                    
MEM_TO_REG          CMP.B   #$4, D6
                    BEQ     INVALID_OPCODE
                    BSR     PRINT_MOVEM
                    BSR     FIND_SIZE
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.W  (A0)+, D3               ; grab the next 16 bits that tell us which registers are saved to memory     
                    BSR     PRINT_LIST              ; Prints list of registers being saved
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
REG_TO_MEM          CMP.B   #$3, D6
                    BEQ     INVALID_OPCODE
                    BSR     PRINT_MOVEM
                    BSR     FIND_SIZE
                    MOVE.W  (A0)+, D3
                    BSR     PRINT_LIST
                    BSR     OPCODE_BREAK
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
                    

**************************LEA*******************************
OPCODE_LEA          CLR.L   D3                      ; Clear flag if it was set

                    BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA
                    CMP.B   #$2, D6
                    BEQ     LOAD_LEA
                    CMP.B   #$7, D6
                    BEQ     LOAD_LEA
                    
                    
LOAD_LEA            BSR     PRINT_LEA
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.B  #'A', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************NEG*******************************
OPCODE_NEG          BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA
                    BSR     GRAB_FOURTH_HEX
                    
                    CMP.B   #$1, D6
                    BEQ     INVALID_OPCODE
                    CMP.B   #$5, D6
                    BEQ     INVALID_OPCODE
                    CMP.B   #$6, D6
                    BEQ     INVALID_OPCODE
                    CMP.B   #$3C, D2
                    BGE     INVALID_OPCODE

LOAD_NEG            BSR     PRINT_NEG
                    BSR     FIND_SIZE
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************JSR*******************************
OPCODE_JSR          BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA
                    
                    CMP.B   #$2, D5
                    BNE     INVALID_OPCODE
                    CMP.B   #$2, D6
                    BEQ     LOAD_JSR
                    CMP.B   #$7, D6
                    BNE     INVALID_OPCODE
                    CMP.B   #$4, D7
                    BEQ     INVALID_OPCODE
                    
LOAD_JSR            BSR     PRINT_JSR
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************RTS*******************************
OPCODE_RTS          BSR     GRAB_FOURTH_HEX

                    CMP.B   #$5, D2
                    BNE     INVALID_OPCODE
                    
                    BSR     PRINT_RTS
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************SUBQ******************************
OPCODE_SUBQ         BSR     GRAB_SECOND_HEX
                    AND.B   #$1, D2                 ; Second hex must be odd
                    BEQ     INVALID_OPCODE
                    
                    BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA
                    
                    BSR     GRAB_LAST_BYTE
                    CMP.B   #$3C, D2                ; EA can't be literal
                    BGE     INVALID_OPCODE
                    
LOAD_SUBQ           BSR     PRINT_SUBQ
                    BSR     FIND_SIZE
                    BSR     HEX                     ; Loads '#$' into Buffer
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************BCS*******************************
OPCODE_BCS          BSR     GRAB_LAST_BYTE          
                    BSR     PRINT_BCS
                    BSR     GET_DISPLACEMENT        ; Displacement determines the distance of branch and
                    RTS                             ; calculates the address

**************************BGE*******************************
OPCODE_BGE          BSR     GRAB_LAST_BYTE
                    BSR     PRINT_BGE
                    BSR     GET_DISPLACEMENT
                    RTS

**************************BLT*******************************
OPCODE_BLT          BSR     GRAB_LAST_BYTE
                    BSR     PRINT_BLT
                    BSR     GET_DISPLACEMENT
                    RTS

**************************BVC*******************************
OPCODE_BVC          BSR     GRAB_LAST_BYTE
                    BSR     PRINT_BVC
                    BSR     GET_DISPLACEMENT
                    RTS

**************************BRA*******************************
OPCODE_BRA          BSR     GRAB_LAST_BYTE
                    BSR     PRINT_BRA
                    BSR     GET_DISPLACEMENT
                    RTS

**************************DIVS******************************
OPCODE_DIVS         BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP                 ; OP REG stored in D4, OP MODE stored in D5
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA                 ; EA MODE stored in D6, EA REG stored in D7
                    BRA     LOAD_DIVS         

LOAD_DIVS           CMP.B   #$1, D6
                    BLE     INVALID_OPCODE
                    BSR     PRINT_DIVS
                    BSR     PRINT_WORD
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS 

**************************OR********************************
OPCODE_OR           BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP                 ; OP REG stored in D4, OP MODE stored in D5
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA                 ; EA MODE stored in D6, EA REG stored in D7
                    CMP.B   #$4, D5 
                    BLT     LOAD_OR 
                    BRA     LOAD_OR_EA   
 

LOAD_OR             BSR     PRINT_OR       
                    BSR     FIND_SIZE
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS                

LOAD_OR_EA         CMP.B   #$1, D6
                    BLE     INVALID_OPCODE
                    BSR     PRINT_OR       
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************SUB*******************************
OPCODE_SUB          BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP                 ; OP REG stored in D4, OP MODE stored in D5
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA                 ; EA MODE stored in D6, EA REG stored in D7
                    CMP.B   #$4, D5                 ; If second octal is 0-3 then it uses datareg
                    BLT     LOAD_SUB                
                    BRA     LOAD_SUB_EA             ; Else it uses EA

LOAD_SUB            BSR     PRINT_SUB
                    BSR     FIND_SIZE
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS                

LOAD_SUB_EA         CMP.B   #$1, D6                 ; Can't use address reg
                    BLE     INVALID_OPCODE
                    BSR     PRINT_SUB
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS                
    
**************************EOR*******************************
OPCODE_EOR          CLR.L   D3
                    BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP                 ; OP REG stored in D4, OP MODE stored in D5
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA                 ; EA MODE stored in D6, EA REG stored in D7

                    CMP.B   #$4, D5
                    BLT     INVALID_OPCODE 
                    CMP.B   #$7, D5  
                    BEQ     INVALID_OPCODE     
                    BRA     LOAD_EOR             

LOAD_EOR            CMP.B   #$1, D6
                    BEQ     INVALID_OPCODE
                    BSR     PRINT_EOR
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+          
                    BSR     FIND_SRC_REG       
                    BSR     OPCODE_BREAK
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS      

**************************CMP*******************************
OPCODE_CMP          BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP                 ; OP REG stored in D4, OP MODE stored in D5
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA                 ; EA MODE stored in D6, EA REG stored in D7
                    BRA     LOAD_CMP

LOAD_CMP            BSR     PRINT_CMP
                    BSR     FIND_SIZE
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************MULS******************************
OPCODE_MULS         BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA
                    
                    CMP.B   #$7, D5
                    BNE     INVALID_OPCODE
                    CMP.B   #$2, D6                     ; EA Mode can't be Address register
                    BEQ     INVALID_OPCODE
                    
                    MOVE.B  #$1, D5                     ; Force MULS to size WORD
                    BSR     PRINT_MULS
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************ADD*******************************
OPCODE_ADD          BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP                 ; OP REG stored in D4, OP MODE stored in D5
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA                 ; EA MODE stored in D6, EA REG stored in D7
                    CMP.B   #$4, D5 
                    BLT     LOAD_ADD
                    BRA     LOAD_ADD_EA 
 

LOAD_ADD            BSR     PRINT_ADD   
                    BSR     FIND_SIZE
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS                

LOAD_ADD_EA         CMP.B   #$1, D6
                    BLE     INVALID_OPCODE
                    BSR     PRINT_ADD   
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************ADDA******************************
OPCODE_ADDA         BSR     GRAB_MID_BYTE
                    BSR     GRAB_OP             ; OP REG stored in D4, OP MODE stored in D5
                    BSR     GRAB_LAST_BYTE
                    BSR     GRAB_EA             ; EA MODE stored in D6, EA REG stored in D7
                    
                    CMP.B   #$3, D5
                    BNE     ADDA_LONG
                    MOVE.B  #$1, D5
                    BRA     LOAD_ADDA
ADDA_LONG           CMP.B   #$7, D5
                    BNE     INVALID_OPCODE
                    MOVE.B  #$2, D5
                
LOAD_ADDA           BSR     PRINT_ADDA  
                    BSR     FIND_SIZE
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_BREAK
                    MOVE.B  #'A', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS   

**************************LSR*******************************
OPCODE_LSR          AND.B   #$4, D6
                    BNE     LOAD_LSR_REG

                    CMP.B   #$0, D4
                    BNE     LOAD_LSR_COUNT
                    ADD.B   #$8, D4
LOAD_LSR_COUNT      BSR     PRINT_LSR
                    BSR     FIND_SIZE
                    BSR     HEX
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_LSR_REG        BSR     PRINT_LSR
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_LSR_EA         CMP.B   #$1, D4
                    BNE     INVALID_OPCODE
                    CMP.B   #$7, D6
                    BNE     LSR_GOOD
                    CMP.B   #$4, D7
                    BEQ     INVALID_OPCODE
LSR_GOOD            BSR     PRINT_LSR
                    MOVE.B  #TAB, (A1)+             ; Loads tabs into buffer for appropriate spacing
                    MOVE.B  #TAB, (A1)+
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

**************************LSL*******************************
OPCODE_LSL          AND.B   #$4, D6
                    BNE     LOAD_LSL_REG

                    CMP.B   #$0, D4
                    BNE     LOAD_LSL_COUNT
                    ADD.B   #$8, D4
LOAD_LSL_COUNT      BSR     PRINT_LSL
                    BSR     FIND_SIZE
                    BSR     HEX
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_LSL_REG        BSR     PRINT_LSL
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_LSL_EA         CMP.B   #$1, D4
                    BNE     INVALID_OPCODE
                    CMP.B   #$7, D6
                    BNE     LSL_GOOD
                    CMP.B   #$4, D7
                    BEQ     INVALID_OPCODE
LSL_GOOD            BSR     PRINT_LSL
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
**************************ASR*******************************
OPCODE_ASR          AND.B   #$4, D6
                    BNE     LOAD_ASR_REG

                    CMP.B   #$0, D4
                    BNE     LOAD_ASR_COUNT
                    ADD.B   #$8, D4
LOAD_ASR_COUNT      BSR     PRINT_ASR
                    BSR     FIND_SIZE
                    BSR     HEX
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_ASR_REG        BSR     PRINT_ASR
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_ASR_EA         CMP.B   #$0, D4
                    BNE     INVALID_OPCODE
                    CMP.B   #$7, D6
                    BNE     ASR_GOOD
                    CMP.B   #$4, D7
                    BEQ     INVALID_OPCODE
ASR_GOOD            BSR     PRINT_ASR
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS


**************************ASL*******************************
OPCODE_ASL          AND.B   #$4, D6
                    BNE     LOAD_ASL_REG

                    CMP.B   #$0, D4
                    BNE     LOAD_ASL_COUNT
                    ADD.B   #$8, D4
LOAD_ASL_COUNT      BSR     PRINT_ASL
                    BSR     FIND_SIZE
                    BSR     HEX
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_ASL_REG        BSR     PRINT_ASL
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_ASL_EA         CMP.B   #$0, D4
                    BNE     INVALID_OPCODE
                    CMP.B   #$7, D6
                    BNE     ASL_GOOD
                    CMP.B   #$4, D7
                    BEQ     INVALID_OPCODE
ASL_GOOD            BSR     PRINT_ASL
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS


**************************ROR*******************************
OPCODE_ROR          AND.B   #$4, D6
                    BNE     LOAD_ROR_REG

                    CMP.B   #$0, D4
                    BNE     LOAD_ROR_COUNT
                    ADD.B   #$8, D4
LOAD_ROR_COUNT      BSR     PRINT_ROR
                    BSR     FIND_SIZE
                    BSR     HEX
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_ROR_REG        BSR     PRINT_ROR
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_ROR_EA         CMP.B   #$3, D4
                    BNE     INVALID_OPCODE
                    CMP.B   #$7, D6
                    BNE     ROR_GOOD
                    CMP.B   #$4, D7
                    BEQ     INVALID_OPCODE
ROR_GOOD            BSR     PRINT_ROR
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS


**************************ROL*******************************
OPCODE_ROL          AND.B   #$4, D6
                    BNE     LOAD_ROL_REG

                    CMP.B   #$0, D4
                    BNE     LOAD_ROL_COUNT
                    ADD.B   #$8, D4
LOAD_ROL_COUNT      BSR     PRINT_ROL
                    BSR     FIND_SIZE
                    BSR     HEX
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_ROL_REG        BSR     PRINT_ROL
                    BSR     FIND_SIZE
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_SRC_REG
                    BSR     OPCODE_BREAK
                    MOVE.B  #'D', (A1)+
                    BSR     FIND_EA_REG
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
LOAD_ROL_EA         CMP.B   #$3, D4
                    BNE     INVALID_OPCODE
                    CMP.B   #$7, D6
                    BNE     ROL_GOOD
                    CMP.B   #$4, D7
                    BEQ     INVALID_OPCODE
ROL_GOOD            BSR     PRINT_ROL
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    BSR     FIND_EA_MODE
                    BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS

************************************************************
*FIND_EA_MODE: Using D6, it directs the flow to the 
*               appropriate Effective Address
*PRE-CONDITIONS: D6 must contain the EA mode octal value
*POST-CONDITIONS: Directs to appropriate effective address
*               and loads it into the Buffer
************************************************************

FIND_EA_MODE        CMP.B   #$0, D6
                    BEQ     PRINT_DATAREG
                    CMP.B   #$1, D6
                    BEQ     PRINT_ADDREG
                    CMP.B   #$2, D6
                    BEQ     PRINT_INDIRECT
                    CMP.B   #$3, D6
                    BEQ     PRINT_INDIRECT_POST
                    CMP.B   #$4, D6
                    BEQ     PRINT_INDIRECT_PRE
                    CMP.B   #$7, D6
                    BEQ     PRINT_SPECIAL
                    BRA     INVALID_OPCODE
EA_MODE_FOUND       RTS

************************************************************
*FIND_EA_MODE_DST: Using D5, it directs the flow to the
*               appropriate Effective Address
*PRE-CONDITIONS: D5 must contain the DST EA mode octal value
*POST-CONDITIONS: Directs to appropriate effective address
*               and loads it into the Buffer
************************************************************

FIND_EA_MODE_DST    CMP.B   #$0, D5
                    BEQ     PRINT_DATAREG
                    CMP.B   #$1, D5
                    BEQ     PRINT_ADDREG
                    CMP.B   #$2, D5
                    BEQ     PRINT_INDIRECT
                    CMP.B   #$3, D5
                    BEQ     PRINT_INDIRECT_POST
                    CMP.B   #$4, D5
                    BEQ     PRINT_INDIRECT_PRE
                    CMP.B   #$7, D5
                    BEQ     PRINT_SPECIAL_DST
                    BRA     INVALID_OPCODE
                    RTS

***********************PRINT_DATAREG************************

PRINT_DATAREG       MOVE.B  #'D', (A1)+

                    CMP.B   #$1, D3                 ; flag to determine if DST EA Mode
                    BEQ     PRINT_SRC_DATAREG
                    BSR     FIND_EA_REG             ; Adds register of effective address to the Buffer
                    BRA     EA_MODE_FOUND
                    
PRINT_SRC_DATAREG   BSR     FIND_SRC_REG            ; Adds register of effective address in the src position
                    BRA     EA_MODE_FOUND           ; to the buffer
***********************PRINT_ADDREG*************************

PRINT_ADDREG        MOVE.B  #'A', (A1)+

                    CMP.B   #$1, D3
                    BEQ     PRINT_SRC_ADDREG
                    BSR     FIND_EA_REG
                    BRA     EA_MODE_FOUND

PRINT_SRC_ADDREG    BSR     FIND_SRC_REG
                    BRA     EA_MODE_FOUND
***********************PRINT_INDIRECT***********************

PRINT_INDIRECT      MOVE.B  #'(', (A1)+
                    MOVE.B  #'A', (A1)+
                    
                    CMP.B   #$1, D3
                    BEQ     PRINT_SRC_INDIRECT
                    BSR     FIND_EA_REG
                    MOVE.B  #')', (A1)+
                    BRA     EA_MODE_FOUND

PRINT_SRC_INDIRECT  BSR     FIND_SRC_REG
                    MOVE.B  #')', (A1)+
                    BRA     EA_MODE_FOUND
***********************PRINT_INDIRECT_POST******************

PRINT_INDIRECT_POST MOVE.B  #'(', (A1)+
                    MOVE.B  #'A', (A1)+
                    
                    CMP.B   #$1, D3
                    BEQ     PRINT_SRC_IND_POST
                    BSR     FIND_EA_REG
                    MOVE.B  #')', (A1)+
                    MOVE.B  #'+', (A1)+
                    BRA     EA_MODE_FOUND

PRINT_SRC_IND_POST  BSR     FIND_SRC_REG
                    MOVE.B  #')', (A1)+
                    MOVE.B  #'+', (A1)+
                    BRA     EA_MODE_FOUND
***********************PRINT_INDIRECT_PRE*******************

PRINT_INDIRECT_PRE  MOVE.B  #'-', (A1)+
                    MOVE.B  #'(', (A1)+
                    MOVE.B  #'A', (A1)+
                    
                    CMP.B   #$1, D3
                    BEQ     PRINT_SRC_IND_PRE
                    BSR     FIND_EA_REG
                    MOVE.B  #')', (A1)+
                    BRA     EA_MODE_FOUND

PRINT_SRC_IND_PRE   BSR     FIND_SRC_REG
                    MOVE.B  #')', (A1)+
                    BRA     EA_MODE_FOUND
***********************PRINT_SPECIAL************************

PRINT_SPECIAL       CMP.B   #$0, D7
                    BEQ     PRINT_DIRECT_W
                    CMP.B   #$1, D7
                    BEQ     PRINT_DIRECT_L
                    CMP.B   #$4, D7
                    BEQ     PRINT_IMMEDIATE
                    BRA     INVALID_OPCODE

***********************PRINT_SPECIAL_DST********************

PRINT_SPECIAL_DST   CMP.B   #$0, D4
                    BEQ     PRINT_DIRECT_W
                    CMP.B   #$1, D4
                    BEQ     PRINT_DIRECT_L
                    CMP.B   #$4, D4
                    BEQ     PRINT_IMMEDIATE
                    BRA     INVALID_OPCODE
                    
***********************PRINT_DIRECT_W***********************

PRINT_DIRECT_W      MOVE.B  #'$', (A1)+             ; Adds hex symbol to Buffer
                    MOVE.W  A0, A6                  ; Grabs address that holds direct value
                    CMP.W   (A0)+, A6               ; moves the pointer
                    MOVE.B  #1, D3                  ; Grabs 2 bytes of data
                    BSR     GRAB_DATA               ; Converts the address to be displayed in hex
                    BRA     EA_MODE_FOUND

***********************PRINT_DIRECT_L***********************

PRINT_DIRECT_L      MOVE.B  #'$', (A1)+
                    MOVE.L  A0, A6
                    CMP.L   (A0)+, A6
                    MOVE.B  #3, D3                  ; Grabs 4 bytes of data
                    BSR     GRAB_DATA
                    BRA     EA_MODE_FOUND

***********************PRINT_IMMEDIATE**********************

PRINT_IMMEDIATE     BSR     HEX
                    BSR     GET_SIZE
                    CMP     #$0, D0
                    BEQ     PRINT_IMMEDIATE_B
                    CMP     #$1, D0
                    BEQ     PRINT_IMMEDIATE_W
                    BRA     PRINT_IMMEDIATE_L

***********************PRINT_IMMEDIATE_B********************

PRINT_IMMEDIATE_B   MOVE.W  A0, A6
                    CMP.W   (A0)+, A6
                    MOVE.B  (A6)+, D3               ; Grabs 1 byte of data
                    MOVE.B  #$0, D3
                    BSR     GRAB_DATA
                    BRA     EA_MODE_FOUND

***********************PRINT_IMMEDIATE_W********************

PRINT_IMMEDIATE_W   MOVE.W  A0, A6
                    CMP.W   (A0)+, A6
                    MOVE.B  #1, D3                  ; Grabs 2 byte of data
                    BSR     GRAB_DATA
                    BRA     EA_MODE_FOUND

***********************PRINT_IMMEDIATE_L********************

PRINT_IMMEDIATE_L   MOVE.L  A0, A6
                    CMP.W   (A0)+, A6
                    MOVE.B  #3, D3                  ; Grabs 4 byte of data
                    BSR     GRAB_DATA
                    BRA     EA_MODE_FOUND


************************************************************
*FIND_EA_REG: Takes the decimal value in D7 and converts it
*               to hex.
*PRE-CONDITIONS: D7 must contain the register octal for EA
*POST-CONDITIONS: Converts the value in hex, so it can be 
*               displayed appropriately
************************************************************

FIND_EA_REG         CMP.B   #$8, D7             ; D7 will always be lower than 8
                    BLE     PRINT_EA            ; 8 is for shifting count = 0
                    BRA     INVALID_OPCODE
EA_REG_FOUND        RTS

***********************PRINT_EA*****************************

PRINT_EA            ADD.B   #$30, D7            ; decimal < 10 + 30 = value in hex
                    MOVE.B  D7, (A1)+           ; Add value to Buffer
                    BRA     EA_REG_FOUND

************************************************************
*FIND_SRC_REG: Takes the decimal value in D4 and converts it
*               to hex.
*PRE-CONDITIONS: D4 must contain the register octal for DST
*               (Messed up naming convention, to late to fix)
*POST-CONDITIONS: Converts the value in hex, so it can be 
*               displayed appropriately
************************************************************

FIND_SRC_REG        CMP.B   #$8, D4
                    BLE     PRINT_SRC
                    BRA     INVALID_OPCODE
SRC_REG_FOUND       RTS
                    
***********************PRINT_SRC****************************

PRINT_SRC           ADD.B   #$30, D4
                    MOVE.B  D4, (A1)+
                    BRA     SRC_REG_FOUND

************************************************************
*GET_SIZE: First 2 LSB in D5 contain the size of an OPCODE
*PRE-CONDITIONS: D5 must will have a value less than 7 that
*               represents the size
*POST-CONDITIONS: Masks the size to a standard convention
************************************************************

GET_SIZE            MOVE.W  D5, D0
                    AND.B   #$3, D0
                    RTS

************************************************************
*FIND_SIZE: Takes the value from D5 and determines the 
*               appropriate size of the OPCODE
*PRE-CONDITIONS: D5 must contain a value less than 3
*POST-CONDITIONS: Prints .B when D5 is 0, .W when D5 is 1
*                and .L when D5 is 2
************************************************************

FIND_SIZE           AND.B   #$03, D5
                    CMP.B   #0, D5
                    BEQ     PRINT_BYTE
                    CMP.B   #1, D5
                    BEQ     PRINT_WORD
                    CMP.B   #2, D5
                    BEQ     PRINT_LONG
                    BRA     INVALID_OPCODE
SIZE_FOUND          RTS
                                        
************************************************************
*GET_DISPLACEMENT: Determines the distance of a branch and
*               prints the address that the branch will move to
*PRE-CONDITIONS: A0 points to the next address.
*POST-CONDITIONS: Branches are printed with their destination
*               address.
************************************************************

GET_DISPLACEMENT    BSR     GRAB_LAST_BYTE
                    CMP.B   #$00, D2                ; check if displacement is 16 bit
                    BEQ     WORD_DISPLACEMENT
                    CMP.B   #$FF, D2                ; Check if displacement is 32 bit
                    BEQ     LONG_DISPLACEMENT
                    BRA     BYTE_DISPLACEMENT
FOUND_DISPLACEMENT  BSR     OPCODE_END
                    BSR     PRINT_BUFFER
                    RTS
                    
***********************BYTE_DISPLACEMENT********************

BYTE_DISPLACEMENT   MOVE.L  A0, CURRENT_ADD
                    CMP.B   #$80, D2                ; check if leading bit is negative
                    BCS     POS_BYTE                ; if carry set then displacment is positive
                    BRA     NEG_BYTE                ; else it's negative
                    
POS_BYTE            MOVE.B  #$3, D3                 ; grabs Long size address
                    ADD.L   D2, CURRENT_ADD         ; D2 contains displacement in hex
                    BSR     HEX
                    LEA     CURRENT_ADD, A6         ; position branch address to be converted
                    BSR     GRAB_DATA               ; converts address in A6 to hex
                    BRA     FOUND_DISPLACEMENT

NEG_BYTE            MOVE.B  #$3, D3
                    EOR.B   #$FF, D2                ; if negative, perform 2's complement
                    SUB.L   D2, CURRENT_ADD         ; subtract two's complement from current address
                    SUB.L   #$1, CURRENT_ADD        ; to make address even
                    BSR     HEX
                    LEA     CURRENT_ADD, A6
                    BSR     GRAB_DATA
                    BRA     FOUND_DISPLACEMENT

***********************WORD_DISPLACEMENT********************

WORD_DISPLACEMENT   MOVE.L  A0, CURRENT_ADD
                    MOVE.W  (A0)+, D2               ; store word size address into D2
                    CMP.W   #$8000, D2              ; check if negative or positive
                    BCS     POS_WORD
                    BRA     NEG_WORD

POS_WORD            MOVE.B  #$3, D3
                    ADD.L   D2, CURRENT_ADD
                    BSR     HEX
                    LEA     CURRENT_ADD, A6
                    BSR     GRAB_DATA
                    BRA     FOUND_DISPLACEMENT
                    
NEG_WORD            MOVE.B  #$3, D3
                    EOR.W   #$FFFF, D2
                    SUB.L   D2, CURRENT_ADD
                    SUB.L   #$1, CURRENT_ADD
                    BSR     HEX
                    LEA     CURRENT_ADD, A6
                    BSR     GRAB_DATA
                    BRA     FOUND_DISPLACEMENT
                    
***********************LONG_DISPLACEMENT********************

LONG_DISPLACEMENT   MOVE.L  A0, CURRENT_ADD
                    MOVE.L  (A0)+, D2               ; store long address into D2
                    CMP.L   #$80000000, D2          ; check if negative or positive
                    BCS     POS_LONG                
                    BRA     NEG_LONG

POS_LONG            MOVE.B  #$3, D3
                    ADD.L   D2, CURRENT_ADD
                    BSR     HEX
                    LEA     CURRENT_ADD, A6
                    BSR     GRAB_DATA
                    BRA     FOUND_DISPLACEMENT
                    
NEG_LONG            MOVE.B  #$3, D3
                    EOR.L   #$FFFFFFFF, D2
                    SUB.L   D2, CURRENT_ADD
                    SUB.L   #$1, CURRENT_ADD
                    BSR     HEX
                    LEA     CURRENT_ADD, A6
                    BSR     GRAB_DATA
                    BRA     FOUND_DISPLACEMENT

************************************************************
*PRINT_LIST: Adds the list of registers (used by MOVEM) to
*               the buffer to be printed
*PRE-CONDITIONS: D3 is clear.
*POST-CONDITIONS: Buffer contains registers that are being 
*               saved or restored with MOVEM
************************************************************

PRINT_LIST          CMP.B   #$4, D6             ; If EA mode is 4 then it uses pre-decrement
                    BEQ     PRE_DEC
                    
                    LSR.W   #$1, D3             ; Shift right to capture LSB, Register is read from right to left
                    BCC     PRE_D1              ; If bit is 0 move to the next register
                    BSR     LIST_HELPER         ; Adds back slashes to buffer if needed
                    MOVE.B  #'D', (A1)+         ; Add register to buffer
                    MOVE.B  #'0', (A1)+
PRE_D1              LSR.W   #$1, D3             ; shift left again to capture MSB
                    BCC     PRE_D2              ; repeat process until all registers are accounted for
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'1', (A1)+
PRE_D2              LSR.W   #$1, D3
                    BCC     PRE_D3
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'2', (A1)+
PRE_D3              LSR.W   #$1, D3
                    BCC     PRE_D4
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'3', (A1)+
PRE_D4              LSR.W   #$1, D3
                    BCC     PRE_D5
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'4', (A1)+
PRE_D5              LSR.W   #$1, D3
                    BCC     PRE_D6
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'5', (A1)+
PRE_D6              LSR.W   #$1, D3
                    BCC     PRE_D7
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'6', (A1)+
PRE_D7              LSR.W   #$1, D3
                    BCC     PRE_A0
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'7', (A1)+
PRE_A0              LSR.W   #$1, D3
                    BCC     PRE_A1
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'0', (A1)+
PRE_A1              LSR.W   #$1, D3
                    BCC     PRE_A2
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'1', (A1)+
PRE_A2              LSR.W   #$1, D3
                    BCC     PRE_A3
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'2', (A1)+
PRE_A3              LSR.W   #$1, D3
                    BCC     PRE_A4
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'3', (A1)+
PRE_A4              LSR.W   #$1, D3
                    BCC     PRE_A5
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'4', (A1)+
PRE_A5              LSR.W   #$1, D3
                    BCC     PRE_A6
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'5', (A1)+
PRE_A6              LSR.W   #$1, D3
                    BCC     PRE_A7
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'6', (A1)+
PRE_A7              LSR.W   #$1, D3
                    BCC     PRINT_LIST_DONE
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'7', (A1)+
                    RTS 
                
PRE_DEC             LSL.W   #$1, D3             ; shift left to grab the MSB, Register is read from left to right
                    BCC     POST_D1             ; if bit was zero move on to the next register
                    BSR     LIST_HELPER         ; adds back slashes if needed
                    MOVE.B  #'D', (A1)+         ; add register to Buffer
                    MOVE.B  #'0', (A1)+
POST_D1             LSL.W   #$1, D3             ; shift left again
                    BCC     POST_D2             ; repeat until all register are accounted for
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'1', (A1)+
POST_D2             LSL.W   #$1, D3
                    BCC     POST_D3
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'2', (A1)+
POST_D3             LSL.W   #$1, D3
                    BCC     POST_D4
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'3', (A1)+
POST_D4             LSL.W   #$1, D3
                    BCC     POST_D5
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'4', (A1)+
POST_D5             LSL.W   #$1, D3
                    BCC     POST_D6
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'5', (A1)+
POST_D6             LSL.W   #$1, D3
                    BCC     POST_D7
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'6', (A1)+
POST_D7             LSL.W   #$1, D3
                    BCC     POST_A0
                    BSR     LIST_HELPER
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'7', (A1)+
POST_A0             LSL.W   #$1, D3
                    BCC     POST_A1
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'0', (A1)+
POST_A1             LSL.W   #$1, D3
                    BCC     POST_A2
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'1', (A1)+
POST_A2             LSL.W   #$1, D3
                    BCC     POST_A3
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'2', (A1)+
POST_A3             LSL.W   #$1, D3
                    BCC     POST_A4
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'3', (A1)+
POST_A4             LSL.W   #$1, D3
                    BCC     POST_A5
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'4', (A1)+
POST_A5             LSL.W   #$1, D3
                    BCC     POST_A6
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'5', (A1)+
POST_A6             LSL.W   #$1, D3
                    BCC     POST_A7
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'6', (A1)+
POST_A7             LSL.W   #$1, D3
                    BCC     PRINT_LIST_DONE
                    BSR     LIST_HELPER
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #'7', (A1)+ 

PRINT_LIST_DONE     RTS

************************************************************
*LIST_HELPER: Helps Print_LIST store registers in the buffer
*               when using MOVEM
*PRE-CONDITIONS: D0 is cleared when using MOVEM
*POST-CONDITIONS: If D0 is 0, set D0 to 1 (acts as a flag)
*               else add a back slash to the buffer
************************************************************

LIST_HELPER         CMP.B   #1, D0
                    BEQ     PRINT_SLASH
                    MOVE.B  #1, D0
                    RTS
                    
PRINT_SLASH         MOVE.B  #'/', (A1)+
                    RTS
                                        
***********************PRINT_BYTE***************************

PRINT_BYTE          MOVE.B  #'.', (A1)+
                    MOVE.B  #'B', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    BRA     SIZE_FOUND

***********************PRINT_WORD***************************

PRINT_WORD          MOVE.B  #'.', (A1)+
                    MOVE.B  #'W', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    BRA     SIZE_FOUND

***********************PRINT_LONG***************************

PRINT_LONG          MOVE.B  #'.', (A1)+
                    MOVE.B  #'L', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    BRA     SIZE_FOUND

***********************INVALID_OPCODE***********************

INVALID_OPCODE      MOVE.B  #TAB, (A1)+         ; adds tab to buffer
                    BSR     OPCODE_END          ; add null terminator at the end
                    LEA     BUFFER, A1          ; print whats in the buffer
                    MOVE.B  #14, D0
                    TRAP #15
                    LEA     OPCODE_ERROR, A1    ; output error message
                    BSR     PRINT_MESSAGE
                    RTS

************************************************************
*PRINT_ORI: Adds ORI to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_ORI           MOVE.B  #'O', (A1)+
                    MOVE.B  #'R', (A1)+
                    MOVE.B  #'I', (A1)+
                    RTS

************************************************************
*PRINT_BCLR: Adds BCLR to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_BCLR          MOVE.B  #'B', (A1)+
                    MOVE.B  #'C', (A1)+
                    MOVE.B  #'L', (A1)+
                    MOVE.B  #'R', (A1)+
                    RTS

************************************************************
*PRINT_CMPI: Adds CMPI to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_CMPI          MOVE.B  #'C', (A1)+
                    MOVE.B  #'M', (A1)+
                    MOVE.B  #'P', (A1)+
                    MOVE.B  #'I', (A1)+
                    RTS

************************************************************
*PRINT_MOVEM: Adds MOVEM to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_MOVEM         MOVE.B  #'M', (A1)+
                    MOVE.B  #'O', (A1)+
                    MOVE.B  #'V', (A1)+
                    MOVE.B  #'E', (A1)+
                    MOVE.B  #'M', (A1)+
                    RTS

************************************************************
*PRINT_LEA: Adds LEA to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_LEA           MOVE.B  #'L', (A1)+
                    MOVE.B  #'E', (A1)+
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_NEG: Adds NEG to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_NEG           MOVE.B  #'N', (A1)+
                    MOVE.B  #'E', (A1)+
                    MOVE.B  #'G', (A1)+
                    RTS

************************************************************
*PRINT_JSR: Adds JSR to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_JSR           MOVE.B  #'J', (A1)+
                    MOVE.B  #'S', (A1)+
                    MOVE.B  #'R', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_RTS: Adds RTS to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_RTS           MOVE.B  #'R', (A1)+
                    MOVE.B  #'T', (A1)+
                    MOVE.B  #'S', (A1)+
                    MOVE.B  #$0, (A1)+
                    RTS

************************************************************
*PRINT_SUBQ: Adds SUBQ to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_SUBQ          MOVE.B  #'S', (A1)+
                    MOVE.B  #'U', (A1)+
                    MOVE.B  #'B', (A1)+
                    MOVE.B  #'Q', (A1)+
                    RTS

************************************************************
*PRINT_BCS: Adds BCS to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_BCS           MOVE.B  #'B', (A1)+
                    MOVE.B  #'C', (A1)+
                    MOVE.B  #'S', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_BGE: Adds BGE to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_BGE           MOVE.B  #'B', (A1)+
                    MOVE.B  #'G', (A1)+
                    MOVE.B  #'E', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_BLT: Adds BLT to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_BLT           MOVE.B  #'B', (A1)+
                    MOVE.B  #'L', (A1)+
                    MOVE.B  #'T', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_BVC: Adds BVC to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_BVC           MOVE.B  #'B', (A1)+
                    MOVE.B  #'V', (A1)+
                    MOVE.B  #'C', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_BRA: Adds BRA to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_BRA           MOVE.B  #'B', (A1)+
                    MOVE.B  #'R', (A1)+
                    MOVE.B  #'A', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_DIVS: Adds DIVS to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_DIVS          MOVE.B  #'D', (A1)+
                    MOVE.B  #'I', (A1)+
                    MOVE.B  #'V', (A1)+
                    MOVE.B  #'S', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_OR: Adds OR to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_OR            MOVE.B  #'O', (A1)+
                    MOVE.B  #'R', (A1)+
                    RTS

************************************************************
*PRINT_SUB: Adds SUB to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_SUB           MOVE.B  #'S', (A1)+
                    MOVE.B  #'U', (A1)+
                    MOVE.B  #'B', (A1)+
                    RTS

************************************************************
*PRINT_MOVE: Adds MOVE to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_MOVE          MOVE.B  #'M', (A1)+
                    MOVE.B  #'O', (A1)+
                    MOVE.B  #'V', (A1)+
                    MOVE.B  #'E', (A1)+
                    RTS

************************************************************
*PRINT_MOVEA: Adds MOVEA to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_MOVEA         MOVE.B  #'M', (A1)+
                    MOVE.B  #'O', (A1)+
                    MOVE.B  #'V', (A1)+
                    MOVE.B  #'E', (A1)+
                    MOVE.B  #'A', (A1)+
                    RTS

************************************************************
*PRINT_EOR: Adds EOR to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_EOR           MOVE.B  #'E', (A1)+
                    MOVE.B  #'O', (A1)+
                    MOVE.B  #'R', (A1)+                    
                    RTS

************************************************************
*PRINT_CMP: Adds CMP to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_CMP           MOVE.B  #'C', (A1)+
                    MOVE.B  #'M', (A1)+
                    MOVE.B  #'P', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_MULS: Adds MULS to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_MULS          MOVE.B  #'M', (A1)+
                    MOVE.B  #'U', (A1)+
                    MOVE.B  #'L', (A1)+
                    MOVE.B  #'S', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_ADD: Adds ADD to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_ADD           MOVE.B  #'A', (A1)+
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #TAB, (A1)+
                    MOVE.B  #TAB, (A1)+
                    RTS

************************************************************
*PRINT_ADDA: Adds ADDA to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_ADDA          MOVE.B  #'A', (A1)+
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'D', (A1)+
                    MOVE.B  #'A', (A1)+
                    RTS

************************************************************
*PRINT_LSR: Adds LSR to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_LSR           MOVE.B  #'L', (A1)+
                    MOVE.B  #'S', (A1)+
                    MOVE.B  #'R', (A1)+
                    RTS

************************************************************
*PRINT_LSL: Adds LSL to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_LSL           MOVE.B  #'L', (A1)+
                    MOVE.B  #'S', (A1)+
                    MOVE.B  #'L', (A1)+
                    RTS

************************************************************
*PRINT_ASR: Adds ASR to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_ASR           MOVE.B  #'A', (A1)+
                    MOVE.B  #'S', (A1)+
                    MOVE.B  #'R', (A1)+
                    RTS

************************************************************
*PRINT_ASL: Adds ASL to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_ASL           MOVE.B  #'A', (A1)+
                    MOVE.B  #'S', (A1)+
                    MOVE.B  #'L', (A1)+
                    RTS

************************************************************
*PRINT_ROR: Adds ROR to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_ROR           MOVE.B  #'R', (A1)+
                    MOVE.B  #'O', (A1)+
                    MOVE.B  #'R', (A1)+
                    RTS

************************************************************
*PRINT_ROL: Adds ROL to the buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Adds OPCODE to the buffer to be printed
************************************************************

PRINT_ROL           MOVE.B  #'R', (A1)+
                    MOVE.B  #'O', (A1)+
                    MOVE.B  #'L', (A1)+
                    RTS
                    
************************************************************
*PRINT_ADDRESS: adds the current address to the print buffer
*PRE-CONDITIONS: A0 contains the current address
*POST-CONDITIONS: Grabs address, converts it to hex, and adds
*               it to the buffer
************************************************************

PRINT_ADDRESS       MOVE.L  A0, CURRENT_ADD     ; current address is at A0
                    LEA     CURRENT_ADD, A6     ; loads it's contents into D6
                    MOVE.B  #3, D3              ; to print a Long addres
                    LEA     BUFFER, A1          ; load buffer into A1 to hold address and it's OPCODE
                    BSR     GRAB_DATA           ; converts address to hex
                    MOVE.B  #TAB, (A1)+         ; create a gap between address and OPCODE
                    RTS
                    
************************************************************
*GRAB_FIRST_HEX: Grabs first hex of OPCODE and stores it into D2
*PRE-CONDITIONS: OPCODE is stored in D1
*POST-CONDITIONS: Masks first hex of an OPCODE and stores it in 
*               the LSB position
************************************************************ 
               
GRAB_FIRST_HEX      MOVE.W  D1, D2              ; Make copy of OPCODE
                    AND.W   #$F000, D2          ; Mask to get the 2nd Hex Value
                    MOVE.B  #12, D0             ; Shift to the LSB
                    LSR.W   D0, D2                    
                    RTS

************************************************************
*GRAB_SECOND_HEX: Grabs Second hex of OPCODE and stores it into D2
*PRE-CONDITIONS: OPCODE is stored in D1
*POST-CONDITIONS: Masks second hex of an OPCODE and stores it in 
*               the LSB position
************************************************************ 
               
GRAB_SECOND_HEX     MOVE.W  D1, D2              ; Make copy of OPCODE
                    AND.W   #$0F00, D2          ; Mask to get the 2nd Hex Value
                    LSR.W   #8, D2              ; Shift to the LSB
                    RTS

************************************************************
*GRAB_THIRD_HEX: Grabs third hex of OPCODE and stores it into D2
*PRE-CONDITIONS: OPCODE is stored in D1
*POST-CONDITIONS: Masks third hex of an OPCODE and stores it in 
*               the LSB position
************************************************************
                
GRAB_THIRD_HEX      MOVE.W  D1, D2
                    AND.W   #$00F0, D2
                    LSR.W   #4, D2
                    RTS

************************************************************
*GRAB_FOURTH_HEX: Grabs fourth hex of OPCODE and stores it into D2
*PRE-CONDITIONS: OPCODE is stored in D1
*POST-CONDITIONS: Masks fourth hex of an OPCODE 
************************************************************
                
GRAB_FOURTH_HEX     MOVE.W  D1, D2
                    AND.W   #$000F, D2
                    RTS

************************************************************
*GRAB_FIRST_BYTE: Grabs the MSByte and stored it into D2
*PRE-CONDITIONS: OPCODE is stored in D1
*POST-CONDITIONS: Masks the MSByte of an OPCODE and stores it in
*               the LSByte
************************************************************
                
GRAB_FIRST_BYTE     MOVE.W  D1, D2
                    AND.W   #$FF00, D2          ; Grab first 2 hex values
                    LSR.W   #8, D2
                    RTS

************************************************************
*GRAB_MID_BYTE: Grabs the  middle Byte ( nibble 2 and 3) and 
*               stored it into D2
*PRE-CONDITIONS: OPCODE is stored in D1
*POST-CONDITIONS: Masks the middle Byte of an OPCODE and stores 
*               it in the LSByte
************************************************************
                
GRAB_MID_BYTE       MOVE.W  D1, D2
                    AND.W   #$0FF0, D2          ; Grab middle 2 hex values
                    LSR.W   #4, D2
                    RTS

************************************************************
*GRAB_LAST_BYTE: Grabs the LSByte and stored it into D2
*PRE-CONDITIONS: OPCODE is stored in D1
*POST-CONDITIONS: Masks the LSByte of an OPCODE 
************************************************************
                
GRAB_LAST_BYTE      MOVE.W  D1, D2
                    AND.W   #$00FF, D2          ; Grab last 2 hex value
                    RTS

************************************************************
*GRAB_OP & GRAB_DST: Stores the first octal in D4 and second
*               octal in D5. This holds the mode and register
*               of the DST
*PRE-CONDITIONS: GRAB_MID_BYTE must be used before calling
*POST-CONDITIONS: D4 contains the register and D5 contains
*               the mode of the DST
************************************************************

GRAB_OP             NOP       
GRAB_DST            AND.W   #$FC, D2            ; Mask to grab DST
                    LSR.B   #1, D2              ; shift right 1 bit
                    MOVE.B  D2, D4
                    AND.B   #$70, D4            ; Mask DST Reg
                    LSR.B   #4, D4              ; Shift to LSB
                
                    LSR.B   #1, D2              ; shift right 1 bit
                    MOVE.B  D2, D5
                    AND.B   #$7, D5             ; Mask DST Mode
                    RTS

************************************************************
*GRAB_SRC & GRAB_EA: Stores the third octal in D6 and second
*               octal in D7. This holds the mode and register
*               of the SRC
*PRE-CONDITIONS: GRAB_LAST_BYTE must be used before calling
*POST-CONDITIONS: D6 contains the mode and D7 contains the
*               register of the SRC
************************************************************

GRAB_SRC            NOP         
GRAB_EA             AND.B   #$3F, D2
                    MOVE.B  D2, D7
                    AND.B   #$7, D7             ; Mask EA/SRC REG
                
                    LSL.B   #1, D2
                    MOVE.B  D2, D6
                    AND.B   #$70, D6            ; Mask EA/SRC MODE
                    LSR.B   #4, D6              ; Shift to LSB
                    RTS

************************************************************
*GRAB_REG:
*PRE-CONDITIONS:
*POST-CONDITIONS:
************************************************************

GRAB_REG            MOVE.B  D1, D7
                    AND.B   #$07, D7
                    
                    MOVE.B  D2, D6
                    AND.B   #$E0, D6
                    LSL.B   #4, D6
                    RTS

************************************************************
*PLAY_AGAIN: Asks the user if they would like to run the 
*               disassembler again.
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: If user replies with Y or y, then the Disassembler
*               will start over, else the dissassembler ends
************************************************************

PLAY_AGAIN          BSR     INIT_DATA
                    LEA     AGAIN, A1
                    BSR     PRINT_MESSAGE    
                    MOVE.B  #5, D0
                    TRAP    #15
                    LEA     NEW_LINE, A1
                    BSR     PRINT_MESSAGE
                    CMP.L   #$59, D1                ; If Y disassemble again, if not Y end
                    BEQ     RESTART
                    CMP.L   #$79, D1                ; If y disassemble again
                    BNE     DONE
RESTART             RTS

************************************************************
*OPCODE_BREAK: Adds a comma and space to the buffer. Used to
*               break the SRC and DST apart.
*PRE-CONDITIONS: SRC must be loaded into the buffer
*POST-CONDITIONS: Adds a ', ' to the buffer
************************************************************

OPCODE_BREAK        MOVE.B  #',', (A1)+
                    MOVE.B  #' ', (A1)+
                    RTS

************************************************************
*OPCODE_END: Adds a null terminator to the end of the buffer.
*               used to stop the buffer from printing beyond
*               the desired output.
*PRE-CONDITIONS: OPCODE must be finished and loaded into the
*               buffer
*POST-CONDITIONS: Buffer string has a null terminator added
*               to the end.
************************************************************

OPCODE_END          MOVE.B  #0, (A1)+
                    RTS

************************************************************
*HEX: Adds a pound and dollar symbol to the buffer before a
*               hex value is added to the buffer
*PRE-CONDITIONS: Appropriate data up to the hex value must
*               be added to the buffer
*POST-CONDITIONS: Adds '#$' to the buffer before a hex value
************************************************************
               
HEX                 MOVE.B  #'#', (A1)+
                    MOVE.B  #'$', (A1)+
                    RTS                 
                    
************************************************************
*PRINT_BUFFER: Prints the contents of buffer
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: outputs the contents of buffer to the console
************************************************************

PRINT_BUFFER        LEA      BUFFER, A1
                    MOVE.B  #13, D0
                    TRAP    #15
                    RTS
                                    
************************************************************
*PRINT_MESSAGE: prints a pre-loaded message that is stored in
*               A1
*PRE-CONDITIONS: A1 must contain the pre-loaded message
*POST-CONDITIONS: pre-loaded message is displayed to the console
************************************************************

PRINT_MESSAGE       MOVE.B  #14, D0
                    TRAP    #15
                    RTS

************************************************************
*USER_INPUT_STR: Grabs a users Hex input when giving starting
*               and ending hex values
*PRE-CONDITIONS: N/A
*POST-CONDITIONS: Buffer contains a string of values that
*               needs to be converted
************************************************************
                
USER_INPUT_STR      LEA     BUFFER, A1
                    MOVE.B  #2, D0
                    TRAP    #15
                    RTS
                
DONE    SIMHALT             ; halt simulator

CR                  EQU     $0D
LF                  EQU     $0A
TAB                 EQU     $9

START_ADD           DC.L    0
END_ADD             DC.L    0
                    DC.W    0
CURRENT_ADD         DC.L    0
BUFFER              DS.B    80
NEW_LINE            DC.B    '', CR, LF, 0
START_PRINT         DC.B    'Enter The starting hex address (w/o spaces) to be disassembled: ', 0
END_PRINT           DC.B    'Enter the ending hex address (w/o spaces) to be disassembled: ', 0
CONFIRM_START       DC.B    'Starting Address: ', 0
CONFIRM_END         DC.B    'Ending Address: ', 0
CONFIRM_MESSAGE     DC.B    'Are the starting and ending address correct (Y/N)?: ', 0
CONTINUE            DC.B    'Press Enter to continue to the next page.', 0
OPCODE_ERROR        DC.B    'BAD DATA', CR, LF, 0
AGAIN               DC.B    'If you would like to Disassemble again press Y: ', 0
BAD_INPUT           DC.B    'That is an invalid address. Please try again.', CR, LF, 0

    END    START        ; last line of source












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
