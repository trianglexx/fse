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


PROGRAM Gate_Controller
  VAR
    Start_Loop : BOOL := False;
    one_hour : TIME := T#1h;
    One_Hour_Timer : TON;
    Gate_Open : BOOL := False;
  END_VAR
  VAR_OUTPUT
    Close_Gate_Inst : BOOL := False;
  END_VAR
  VAR_INPUT
    Sensed_Car : BOOL := False;
    Sensed_Car_Inst : BOOL := False;
    Sensed_App : BOOL := False;
    Mobile_Inst : BOOL := False;
    Mobile_Auth : STRING;
  END_VAR
  VAR
    my_defined_str : STRING := '"1234"';
  END_VAR

  One_Hour_Timer(IN := NOT(Start_Loop), PT := one_hour);

  IF One_Hour_Timer.Q THEN
    IF Gate_Open THEN
      Close_Gate_Inst := True;
      Gate_Open := False;
    END_IF;
  END_IF;

  IF Sensed_App THEN
    (* How can I do some authentication here? *)
    IF EQ(Mobile_Auth, my_defined_str) THEN
      Close_Gate_Inst := XOR(Mobile_Inst, Gate_Open);
      Gate_Open := Mobile_Inst;
    END_IF;
  END_IF;

  IF AND(Sensed_Car, Sensed_Car_Inst) THEN
    Close_Gate_Inst := XOR(Sensed_Car_Inst, Gate_Open);
    Gate_Open := Sensed_Car_Inst;
  END_IF;


  Start_Loop := One_Hour_Timer.Q;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : Gate_Controller;
  END_RESOURCE
END_CONFIGURATION
