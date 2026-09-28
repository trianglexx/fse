TYPE
  LOGLEVEL : (CRITICAL, WARNING, INFO, DEBUG) := INFO;
END_TYPE

FUNCTION_BLOCK LOGGER
  VAR_INPUT
    TRIG : BOOL;
    MSG : STRING;
    LEVEL : LOGLEVEL := INFO;
  END_VAR
  VAR
    TRIG0 : BOOL;
  END_VAR

  IF TRIG AND NOT TRIG0 THEN
  {{
   LogMessage(GetFbVar(LEVEL),(char*)GetFbVar(MSG, .body),GetFbVar(MSG, .len));
  }}
  END_IF;
  TRIG0:=TRIG;
END_FUNCTION_BLOCK



FUNCTION_BLOCK python_eval
  VAR_INPUT
    TRIG : BOOL;
    CODE : STRING;
  END_VAR
  VAR_OUTPUT
    ACK : BOOL;
    RESULT : STRING;
  END_VAR
  VAR
    STATE : DWORD;
    BUFFER : STRING;
    PREBUFFER : STRING;
    TRIGM1 : BOOL;
    TRIGGED : BOOL;
  END_VAR

  {extern void __PythonEvalFB(int, PYTHON_EVAL*);__PythonEvalFB(0, data__);}
END_FUNCTION_BLOCK

FUNCTION_BLOCK python_poll
  VAR_INPUT
    TRIG : BOOL;
    CODE : STRING;
  END_VAR
  VAR_OUTPUT
    ACK : BOOL;
    RESULT : STRING;
  END_VAR
  VAR
    STATE : DWORD;
    BUFFER : STRING;
    PREBUFFER : STRING;
    TRIGM1 : BOOL;
    TRIGGED : BOOL;
  END_VAR

  {extern void __PythonEvalFB(int, PYTHON_EVAL*);__PythonEvalFB(1,(PYTHON_EVAL*)(void*)data__);}
END_FUNCTION_BLOCK

FUNCTION_BLOCK python_gear
  VAR_INPUT
    N : UINT;
    TRIG : BOOL;
    CODE : STRING;
  END_VAR
  VAR_OUTPUT
    ACK : BOOL;
    RESULT : STRING;
  END_VAR
  VAR
    py_eval : python_eval;
    COUNTER : UINT;
    ADD10_OUT : UINT;
    EQ13_OUT : BOOL;
    SEL15_OUT : UINT;
    AND7_OUT : BOOL;
  END_VAR

  ADD10_OUT := ADD(COUNTER, 1);
  EQ13_OUT := EQ(N, ADD10_OUT);
  SEL15_OUT := SEL(EQ13_OUT, ADD10_OUT, 0);
  COUNTER := SEL15_OUT;
  AND7_OUT := AND(EQ13_OUT, TRIG);
  py_eval(TRIG := AND7_OUT, CODE := CODE);
  ACK := py_eval.ACK;
  RESULT := py_eval.RESULT;
END_FUNCTION_BLOCK


TYPE
  SuperStatesEnum : (ST_INICIALIZACE, ST_RESET_POSITION_OF_MOTORS, ST_WAIT_FOR_COMMAND, ST_MODE_SELECTION, ST_MANUAL_MODE, ST_AUTOMATIC_MODE, ST_CHECK_POSITION_OF_MOTORS, ST_STOP, ST_EMERGENCY_STOP) := ST_INICIALIZACE;
END_TYPE

PROGRAM SuperStavy
  VAR
    I_Start : BOOL := 1;
    I_PowerOn : BOOL := 1;
    I_StopBtn : BOOL;
    I_StopResBtn : BOOL;
    I_EmStopBtn : BOOL;
    I_EmStopResBtn : BOOL;
    I_ManualSelector : BOOL;
    I_AutomaticSelector : BOOL := 1;
  END_VAR
  VAR
    SuperStates : SuperStatesEnum;
  END_VAR
  VAR
    I_A0 : BOOL;
    I_A1 : BOOL;
    I_B0 : BOOL;
    I_B1 : BOOL;
    I_C0 : BOOL;
    I_C1 : BOOL;
  END_VAR
  VAR
    I_Qt : BOOL;
  END_VAR
  VAR
    Q_A : BOOL;
    Q_B : BOOL;
    Q_C : BOOL;
  END_VAR
  VAR
    Q_PositionOk : BOOL;
    Q_PositionNotOk : BOOL;
    Q_It : BOOL;
    InputArr : ARRAY [0..7] OF BYTE;
    InputWord : INT;
    TRANS_MATX : ARRAY [0..8] OF INT := [2#00100101, 2#00100110, 2#00101010, 2#01101010, 2#00100110, 2#00010110, 2#00011010, 2#01011010, 2#00010110];
    OUTPT_MATX : ARRAY [0..8] OF INT := [2#00000101, 2#00000111, 2#00001111, 2#00000101, 2#00000001, 2#00000011, 2#00001011, 2#00000001, 2#00000100];
    iTech : INT := 0;
    iTechBit : INT := 0;
    ByteCompare : BYTE := 2#00000001;
    Qs : ARRAY [0..7] OF BOOL;
    TechnologicalSequenceState : INT := 0;
    SuperSequenceState : INT := 1;
    TON_0 : TON;
    BlastingTime : TIME := t#5s;
  END_VAR


  IF (I_EMSTOPBTN = true) THEN
    
      SuperStates := ST_EMERGENCY_STOP;
    
  END_IF;



  CASE SuperStates OF
    
    ST_INICIALIZACE:
      SuperSequenceState := 1;
      (*IF (I_Start = true) AND (I_PowerOn = true) THEN*) (*Uprava 06.05.2021*)
        
        SuperStates := ST_RESET_POSITION_OF_MOTORS;
        
      (*END_IF;*)
      
    ST_RESET_POSITION_OF_MOTORS:
      SuperSequenceState := 2;
      Q_A := false;
      Q_B := false;
      Q_C := true;
      IF I_A0 AND I_B0 AND I_C1 THEN 
        Q_PositionOk := true;
        Q_PositionNotOk := false;
        SuperStates := ST_WAIT_FOR_COMMAND;
      END_IF;
      
    ST_WAIT_FOR_COMMAND:
      SuperSequenceState := 3;
      Q_PositionOk := false;
      Q_PositionNotOk := false;
      
      SuperStates := ST_MODE_SELECTION;
      
    ST_MODE_SELECTION:
      SuperSequenceState := 4;
      (*IF (I_ManualSelector) THEN
          SuperStates := ST_MANUAL_MODE; *)  (*Uprava 06.05.2021*)
      (*ELSIF (I_AutomaticSelector) THEN *)
          SuperStates := ST_AUTOMATIC_MODE;
      (*END_IF;*)    (*Uprava 06.05.2021*)
      (*TODO// Comeback from this state to STOP*)
      
    ST_MANUAL_MODE:
      SuperSequenceState := 5;
      I_A0 := 1;
      (*TODO MANUAL MODE AND TRANSITION TO ST_CHECK_MOTORS*)
      
    ST_AUTOMATIC_MODE:
      SuperSequenceState := 6;
      
      (*  Conversion of all BOOL in's, q's to INT    *)
      (*BYTE:                  7  6  5  4  3  2  1  0*)
      (*Inputs localization:   - Qt C1 C0 B1 B0 A1 A0*)
      (*Outpts localization:   -  -  -  - It  C  B  A*)
      (*           I_Qt - Q of timer                 *)
      (*           Q_It - In of timer                *)
      
      InputArr[0] := SHL(bool_to_byte(I_A0),0);
      InputArr[1] := SHL(bool_to_byte(I_A1),1);
      InputArr[2] := SHL(bool_to_byte(I_B0),2);
      InputArr[3] := SHL(bool_to_byte(I_B1),3);
      InputArr[4] := SHL(bool_to_byte(I_C0),4);
      InputArr[5] := SHL(bool_to_byte(I_C1),5);
      InputArr[6] := SHL(bool_to_byte(I_Qt),6);
      
      InputWord := byte_to_int(InputArr[0]) + byte_to_int(InputArr[1]) + byte_to_int(InputArr[2]) + byte_to_int(InputArr[3]) + byte_to_int(InputArr[4]) + byte_to_int(InputArr[5]) + byte_to_int(InputArr[6]);
      
      (*   End of Conversion   *)
      
      
      IF (InputWord = TRANS_MATX[iTech]) THEN
        
        FOR iTechBit:= 0 TO 7 DO                                                            (*Making the outputs HIGH/LOW by going throught bitwise*)
            IF ((int_to_byte(OUTPT_MATX[iTech]) AND SHL(ByteCompare, iTechBit)) <> 0) THEN  (*Going throught one row of OUTPT_MATX and checking, which outputs should be TRUE*)
              Qs[iTechBit] := true;
            ELSE
              Qs[iTechBit] := false;
            END_IF;
        END_FOR;
        
        (*Mapping of outputs*)
        Q_A := Qs[0];
        Q_B := Qs[1];
        Q_C := Qs[2];
        Q_It := Qs[3]; 
        (*End of mapping of outputs*)
        
        TechnologicalSequenceState := iTech;      (*Remembering the technological state*)
        
        iTech := iTech + 1;                       (*Going to the next state*)
        
      END_IF;
      
      (*Actions after on technological sequence is done*)
      IF (iTech > 8) THEN                         (*Program has gone throught all technological states*)
        
        iTech := 0;                               (*Reset sequence*)
      END_IF;
        
     (*ELSIF (iTech = 8) AND NOT (I_AutomaticSelector) THEN  (*Program has gone throught all technological states AND automatic selector is not pressed*)
        
      (*  iTech := 0;                                         (*Reset sequence*) 
      (*  SuperStates := ST_CHECK_POSITION_OF_MOTORS;         (*Go to the next state*)
        
      (*ELSIF (iTech = 8) AND (I_StopBtn) THEN                (*Program has gone throught all technological states AND stop btn is pressed*)
        
       (* SuperStates := ST_STOP;                               (*Go to stop state*)
        
     (* END_IF;*)
      
          
    ST_CHECK_POSITION_OF_MOTORS:
      SuperSequenceState := 7;
      IF (I_A0 = true) AND (I_B0 = true) AND (I_C1 = true) THEN
        Q_PositionOk := true;
        SuperStates := ST_WAIT_FOR_COMMAND;
      ELSE
        Q_PositionOk := true;
        SuperStates := ST_RESET_POSITION_OF_MOTORS;
      END_IF;
      
    ST_STOP:
      SuperSequenceState := 8; 
      (*DO NOTHING*)
      IF (I_StopResBtn) THEN
        SuperStates := ST_AUTOMATIC_MODE;
      END_IF;
      
    ST_EMERGENCY_STOP:
      SuperSequenceState := 0;
      I_PowerOn := false;
      IF (I_EmStopResBtn) THEN
        SuperStates := ST_WAIT_FOR_COMMAND;
      END_IF;
      
  END_CASE;



  (*Function block calling*)

  TON_0(IN := I_B1, PT := BlastingTime, Q => I_Qt);
   

  (*End of Function block calling*)

END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : SuperStavy;
  END_RESOURCE
END_CONFIGURATION
