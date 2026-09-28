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



FUNCTION_BLOCK GetBoolString
  VAR_INPUT
    VALUE : BOOL;
  END_VAR
  VAR_OUTPUT
    CODE : STRING;
  END_VAR

  IF VALUE THEN
    CODE := 'True';
  ELSE
    CODE := 'False';
  END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK Button
  VAR
    ID : STRING;
  END_VAR
  VAR_INPUT
    back_id : STRING;
    sele_id : STRING;
    toggle : BOOL;
    set_state : BOOL;
    state_in : BOOL;
  END_VAR
  VAR_OUTPUT
    state_out : BOOL;
  END_VAR
  VAR
    init_Command : python_eval;
    GetButtonState : GetBoolString;
    setstate_Command : python_eval;
    getstate_Command : python_poll;
    GetButtonToggle : GetBoolString;
    CONCAT2_OUT : STRING;
    CONCAT22_OUT : STRING;
    STRING_TO_INT25_OUT : INT;
    INT_TO_BOOL26_OUT : BOOL;
    AND31_OUT : BOOL;
    CONCAT7_OUT : STRING;
  END_VAR

  GetButtonToggle(VALUE := toggle);
  CONCAT2_OUT := CONCAT('createSVGUIControl("button",back_id="', back_id, '",sele_id="', sele_id, '",toggle=', GetButtonToggle.CODE, ',active=True)');
  init_Command(TRIG := BOOL#1, CODE := CONCAT2_OUT);
  ID := init_Command.RESULT;
  CONCAT22_OUT := CONCAT('int(getAttr(', ID, ',"state",False))');
  getstate_Command(TRIG := init_Command.ACK, CODE := CONCAT22_OUT);
  STRING_TO_INT25_OUT := STRING_TO_INT(getstate_Command.RESULT);
  INT_TO_BOOL26_OUT := INT_TO_BOOL(STRING_TO_INT25_OUT);
  state_out := INT_TO_BOOL26_OUT;
  AND31_OUT := AND(init_Command.ACK, set_state);
  GetButtonState(VALUE := state_in);
  CONCAT7_OUT := CONCAT('setAttr(', ID, ',"state",', GetButtonState.CODE, ')');
  setstate_Command(TRIG := AND31_OUT, CODE := CONCAT7_OUT);
END_FUNCTION_BLOCK

FUNCTION_BLOCK Led
  VAR
    ID : STRING;
  END_VAR
  VAR_INPUT
    back_id : STRING;
    sele_id : STRING;
    state_in : BOOL;
  END_VAR
  VAR
    init_Command : python_eval;
    setstate_Command : python_poll;
    GetLedState : GetBoolString;
    CONCAT2_OUT : STRING;
    CONCAT7_OUT : STRING;
  END_VAR

  CONCAT2_OUT := CONCAT('createSVGUIControl("button",back_id="', back_id, '",sele_id="', sele_id, '",toggle=True,active=False)');
  init_Command(TRIG := BOOL#1, CODE := CONCAT2_OUT);
  ID := init_Command.RESULT;
  GetLedState(VALUE := state_in);
  CONCAT7_OUT := CONCAT('setAttr(', ID, ',"state",', GetLedState.CODE, ')');
  setstate_Command(TRIG := init_Command.ACK, CODE := CONCAT7_OUT);
END_FUNCTION_BLOCK

FUNCTION_BLOCK TextCtrl
  VAR
    ID : STRING;
  END_VAR
  VAR_INPUT
    back_id : STRING;
    set_text : BOOL;
    text : STRING;
  END_VAR
  VAR
    SVGUI_TEXTCTRL : python_eval;
    setstate_Command : python_eval;
    CONCAT1_OUT : STRING;
    AND31_OUT : BOOL;
    CONCAT12_OUT : STRING;
  END_VAR

  CONCAT1_OUT := CONCAT('createSVGUIControl("textControl", back_id="', back_id, '")');
  SVGUI_TEXTCTRL(TRIG := BOOL#1, CODE := CONCAT1_OUT);
  ID := SVGUI_TEXTCTRL.RESULT;
  AND31_OUT := AND(SVGUI_TEXTCTRL.ACK, set_text);
  CONCAT12_OUT := CONCAT('setAttr(', ID, ',"text","', text, '")');
  setstate_Command(TRIG := AND31_OUT, CODE := CONCAT12_OUT);
END_FUNCTION_BLOCK


FUNCTION_BLOCK CounterSFC
  VAR_INPUT
    Reset : BOOL;
  END_VAR
  VAR_OUTPUT
    OUT : INT;
  END_VAR
  VAR
    Cnt : INT;
  END_VAR
  VAR_EXTERNAL CONSTANT
    ResetCounterValue : INT;
  END_VAR

  INITIAL_STEP Start:
  END_STEP

  TRANSITION FROM Start TO ResetCounter
    := Reset;
  END_TRANSITION

  STEP ResetCounter:
    RESETCOUNTER_INLINE1(N);
    RESETCOUNTER_INLINE2(N);
  END_STEP

  ACTION RESETCOUNTER_INLINE1:
    Cnt := ResetCounterValue;
  END_ACTION

  ACTION RESETCOUNTER_INLINE2:
    OUT := Cnt;
  END_ACTION

  TRANSITION FROM ResetCounter TO Start
    := NOT Reset;
  END_TRANSITION

  TRANSITION FROM Start TO Count
    := NOT Reset;
  END_TRANSITION

  STEP Count:
    COUNT_INLINE3(N);
    COUNT_INLINE4(N);
  END_STEP

  ACTION COUNT_INLINE3:
    Cnt := Cnt + 1;
  END_ACTION

  ACTION COUNT_INLINE4:
    OUT := Cnt;
  END_ACTION

  TRANSITION FROM Count TO Start
    := Reset;
  END_TRANSITION

END_FUNCTION_BLOCK

FUNCTION_BLOCK CounterFBD
  VAR_INPUT
    Reset : BOOL;
  END_VAR
  VAR_OUTPUT
    OUT : INT;
  END_VAR
  VAR
    Cnt : INT;
  END_VAR
  VAR_EXTERNAL CONSTANT
    ResetCounterValue : INT;
  END_VAR
  VAR
    ADD4_OUT : INT;
    SEL7_OUT : INT;
  END_VAR

  ADD4_OUT := ADD(1, Cnt);
  SEL7_OUT := SEL(Reset, ADD4_OUT, ResetCounterValue);
  Cnt := SEL7_OUT;
  OUT := Cnt;
END_FUNCTION_BLOCK

FUNCTION_BLOCK CounterIL
  VAR
    Cnt : INT;
  END_VAR
  VAR_INPUT
    Reset : BOOL;
  END_VAR
  VAR_OUTPUT
    OUT : INT;
  END_VAR
  VAR_EXTERNAL CONSTANT
    ResetCounterValue : INT;
  END_VAR

  LD Reset
  JMPC ResetCnt

  (* increment counter *)
  LD Cnt
  ADD 1
  JMP QuitFb

  ResetCnt:
  (* reset counter *)
  LD ResetCounterValue

  QuitFb:
  (* save results *)
  ST Cnt
  ST Out
END_FUNCTION_BLOCK

FUNCTION_BLOCK CounterST
  VAR_INPUT
    Reset : BOOL;
  END_VAR
  VAR
    Cnt : INT;
  END_VAR
  VAR_OUTPUT
    OUT : INT;
  END_VAR
  VAR_EXTERNAL CONSTANT
    ResetCounterValue : INT;
  END_VAR

  IF Reset THEN
    Cnt := ResetCounterValue;
  ELSE
    Cnt := Cnt + 1;
  END_IF;

  Out := Cnt;
END_FUNCTION_BLOCK

FUNCTION_BLOCK CounterLD
  VAR_INPUT
    Reset : BOOL;
  END_VAR
  VAR_OUTPUT
    Out : INT;
  END_VAR
  VAR
    Cnt : INT;
  END_VAR
  VAR_EXTERNAL CONSTANT
    ResetCounterValue : INT;
  END_VAR
  VAR
    ADD4_OUT : INT;
    SEL7_OUT : INT;
  END_VAR

  ADD4_OUT := ADD(1, Cnt);
  SEL7_OUT := SEL(Reset, ADD4_OUT, ResetCounterValue);
  Cnt := SEL7_OUT;
  Out := Cnt;
END_FUNCTION_BLOCK

PROGRAM plc_prg
  VAR_INPUT
    Reset : BOOL;
  END_VAR
  VAR_OUTPUT
    Cnt1 : INT;
    Cnt2 : INT;
    Cnt3 : INT;
    Cnt4 : INT;
    Cnt5 : INT;
  END_VAR
  VAR
    CounterST0 : CounterST;
    CounterFBD0 : CounterFBD;
    CounterSFC0 : CounterSFC;
    CounterIL0 : CounterIL;
    CounterLD0 : CounterLD;
  END_VAR

  CounterST0(Reset := Reset);
  Cnt1 := CounterST0.OUT;
  CounterFBD0(Reset := Reset);
  Cnt2 := CounterFBD0.OUT;
  CounterSFC0(Reset := Reset);
  Cnt3 := CounterSFC0.OUT;
  CounterIL0(Reset := Reset);
  Cnt4 := CounterIL0.OUT;
  CounterLD0(Reset := Reset);
  Cnt5 := CounterLD0.Out;
END_PROGRAM


CONFIGURATION config
  VAR_GLOBAL CONSTANT
    ResetCounterValue : INT := 17;
  END_VAR

  RESOURCE resource1 ON PLC
    TASK plc_task(INTERVAL := T#100ms,PRIORITY := 1);
    PROGRAM plc_task_instance WITH plc_task : plc_prg;
  END_RESOURCE
END_CONFIGURATION
