*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $7000
START:                  ; first instruction of program
           
           SUB.W        D0, $AAAA2222
           SUB.W        D2, D0
           BRA         $6900
           BRA          $7100
           BRA          $0400
           EOR.W          D3, D5
           ADDA         D4, A4
           
            ASR.B        #$8, D7
           ASR.W        D3, D0
           ASR          (A4)
           ASL.L        #$3, D5
           ASL.W        D2, D1
           ASL          (A2)+
           LSR.B        #$8, D7
           LSR.W        D3, D0
           LSR          (A4)
           LSL.L        #$3, D5
           LSL.W        D2, D4
           LSL          (A2)+
           ROR.B        #$8, D7
           ROR.W        D3, D0
           ROR          (A4)
           ROL.L        #$3, D5
           ROL.W        D2, D4
           ROL          (A2)+
           MULS         D2, D5
           MULS         #$3, D3
           MOVE.B       #$5, D6
           MOVE.L       D3, D5
           MOVE.W       A5, D0
           MOVEA.W      D5, A7
           MOVEA.L      D0, A0
           LEA          (A4), A3
           JSR          (A2)
           JSR          $7000
           RTS
           BRA          $7040
           MOVEM.W      D0/D7, -(SP)
           MOVEM.W      (SP)+, D0/D7
           SIMHALT             ; halt simulator

MESSAGE DC.W    'Enter an OP-CODE in Hex: ',0

    END    START        ; last line of source






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
