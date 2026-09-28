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


PROGRAM program0
  VAR
    S1 : BOOL;
    Actual_Input_Signal : BOOL;
    Cylinder_1 : BOOL;
    Cylinder_2 : BOOL;
    Cylinder_3 : BOOL;
    y : BOOL;
    B2 : BOOL;
    B3 : BOOL;
    Reset : BOOL;
    B4 : BOOL;
    B5 : BOOL;
    B6 : BOOL;
    x : BOOL;
    B7 : BOOL;
    TON0 : TON;
    CTU0 : CTU;
    CTU1 : CTU;
    TOF0 : TOF;
    CTU2 : CTU;
    TON1 : TON;
    _TMP_NOT49_OUT : BOOL;
    _TMP_NOT8_OUT : BOOL;
    _TMP_XOR14_OUT : BOOL;
    _TMP_NOT15_OUT : BOOL;
    _TMP_NOT19_OUT : BOOL;
    _TMP_AND17_OUT : BOOL;
    R_TRIG1 : R_TRIG;
    _TMP_GT24_OUT : BOOL;
    _TMP_NOT48_OUT : BOOL;
    R_TRIG2 : R_TRIG;
    _TMP_GT25_OUT : BOOL;
    _TMP_AND29_OUT : BOOL;
    _TMP_SUB28_OUT : INT;
    _TMP_EQ30_OUT : BOOL;
    _TMP_AND32_OUT : BOOL;
    _TMP_NOT33_OUT : BOOL;
    _TMP_EQ36_OUT : BOOL;
    R_TRIG3 : R_TRIG;
    _TMP_XOR44_OUT : BOOL;
  END_VAR

  Actual_Input_Signal := S1;
  _TMP_NOT49_OUT := NOT(Reset);
  Actual_Input_Signal := _TMP_NOT49_OUT;
  S1 := Actual_Input_Signal;
  B7 := Actual_Input_Signal;
  y := B7;
  _TMP_NOT8_OUT := NOT(y);
  Cylinder_1 := _TMP_NOT8_OUT;
  TON0(IN := B2, PT := T#4s);
  _TMP_XOR14_OUT := XOR(B2, TON0.Q);
  Cylinder_2 := _TMP_XOR14_OUT;
  _TMP_NOT15_OUT := NOT(_TMP_XOR14_OUT);
  _TMP_NOT19_OUT := NOT(B6);
  _TMP_AND17_OUT := AND(_TMP_NOT15_OUT, TON0.Q, _TMP_NOT19_OUT);
  Cylinder_3 := _TMP_AND17_OUT;
  R_TRIG1(CLK := Cylinder_3);
  CTU0(CU := R_TRIG1.Q, R := S1, PV := 10);
  _TMP_GT24_OUT := GT(CTU0.CV, 0);
  _TMP_NOT48_OUT := NOT(Cylinder_3);
  R_TRIG2(CLK := _TMP_NOT48_OUT);
  CTU1(CU := R_TRIG2.Q, R := S1, PV := 10);
  _TMP_GT25_OUT := GT(CTU1.CV, 0);
  _TMP_AND29_OUT := AND(_TMP_GT24_OUT, _TMP_GT25_OUT);
  _TMP_SUB28_OUT := SUB(CTU0.CV, CTU1.CV);
  _TMP_EQ30_OUT := EQ(_TMP_SUB28_OUT, 0);
  _TMP_AND32_OUT := AND(_TMP_AND29_OUT, _TMP_EQ30_OUT);
  _TMP_NOT33_OUT := NOT(_TMP_AND32_OUT);
  TOF0(IN := _TMP_NOT33_OUT, PT := T#2s);
  _TMP_EQ36_OUT := EQ(_TMP_AND32_OUT, TOF0.Q);
  R_TRIG3(CLK := _TMP_EQ36_OUT);
  CTU2(CU := R_TRIG3.Q, R := S1, PV := 10);
  x := CTU2.Q;
  TON1(IN := x, PT := T#30s);
  _TMP_XOR44_OUT := XOR(x, TON1.Q);
  Reset := _TMP_XOR44_OUT;
  y := _TMP_EQ36_OUT;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : program0;
  END_RESOURCE
END_CONFIGURATION
