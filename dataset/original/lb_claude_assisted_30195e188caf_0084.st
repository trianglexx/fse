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
    _TMP_ADD10_OUT : UINT;
    _TMP_EQ13_OUT : BOOL;
    _TMP_SEL15_OUT : UINT;
    _TMP_AND7_OUT : BOOL;
  END_VAR

  _TMP_ADD10_OUT := ADD(COUNTER, 1);
  _TMP_EQ13_OUT := EQ(N, _TMP_ADD10_OUT);
  _TMP_SEL15_OUT := SEL(_TMP_EQ13_OUT, _TMP_ADD10_OUT, 0);
  COUNTER := _TMP_SEL15_OUT;
  _TMP_AND7_OUT := AND(_TMP_EQ13_OUT, TRIG);
  py_eval(TRIG := _TMP_AND7_OUT, CODE := CODE);
  ACK := py_eval.ACK;
  RESULT := py_eval.RESULT;
END_FUNCTION_BLOCK


PROGRAM plc2
  VAR
    ColorSensor_RED : INT;
    ColorSensor_GREEN : INT;
    ColorSensor_BLUE : INT;
    RangeSensor : REAL := 100.0;
    Pump : BOOL := FALSE;
    Doser_RED : BOOL := FALSE;
    Doser_BLUE : BOOL := FALSE;
  END_VAR
  VAR
    settleTime : TIME := TIME#5s;
    doseTime : TIME := TIME#1s;
    shutDown : BOOL := FALSE;
    treatmentComplete : BOOL := FALSE;
  END_VAR
  VAR
    stage : INT := 0;
    desiredDistanceFill : REAL := 60.0;
  END_VAR
  VAR
    minRed : INT := 20;
    doseTimer : TON;
    settleTimer : TON;
  END_VAR

  CASE stage OF
      0:  (*Filling stage: it will fill up to a certain amount that corresponds to a certain distance*)
      
          IF RangeSensor > desiredDistanceFill THEN
            Pump := TRUE;
          ELSE
            Pump := FALSE;
            stage := 1;
          END_IF;
          
     1:  (*Treatment stage*)
      
          IF ColorSensor_RED < minRed THEN (*Ensure minimum red value is inserted*)
            stage := 2;
            Doser_RED := TRUE;
            doseTimer(IN:= NOT doseTimer.Q, PT:= doseTime);
            
          ELSIF ColorSensor_RED > ColorSensor_BLUE  THEN (*Ensure blue quantity is > Red *)
            
              stage := 3;
              Doser_BLUE := TRUE;
              doseTimer(IN:= NOT doseTimer.Q, PT:= doseTime);
          
          ELSE  (*Treatment complete*)
            
            stage := 5;
            
          END_IF;
          
      2:  (*Red Dosing Stage*)
      
          IF doseTimer.Q THEN
            Doser_RED := FALSE;
            stage := 4;
            doseTimer(IN:= FALSE);
            settleTimer(IN:= NOT settleTimer.Q, PT:= settleTime); (*let the dose settle*)
          END_IF;
          
      3: (* Blue Dosing Stage*)
      
          IF doseTimer.Q THEN
            Doser_BLUE := FALSE;
            stage := 4;
            doseTimer(IN:= FALSE);
            settleTimer(IN:= NOT settleTimer.Q, PT:= settleTime); (*let the dose settle*)
          END_IF;
          
      4: (*Settling Stage for Dosage*)
      
          IF settleTimer.Q THEN
          stage := 1;
          settleTimer(IN:=FALSE);
          END_IF;
      
      5: (*Treatment Complete*)
      
        treatmentComplete := TRUE;
        
  END_CASE;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#200ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : plc2;
  END_RESOURCE
END_CONFIGURATION
