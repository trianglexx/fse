PROGRAM Mixing
  VAR
    m AT %QX0.0 : BOOL;
    a AT %QX0.1 : BOOL;
    b AT %QX0.2 : BOOL;
    d1 AT %QX0.3 : BOOL;
    d2 AT %QX0.4 : BOOL;
    e1 AT %QX0.5 : BOOL;
    e2 AT %QX0.6 : BOOL;
    f AT %QX0.7 : BOOL;
    g AT %QX1.0 : BOOL;
    l AT %QX1.1 : BOOL;
    EA AT %QX2.0 : BOOL;
    EB AT %QX2.1 : BOOL;
    ED AT %QX2.2 : BOOL;
    EE AT %QX2.3 : BOOL;
    EF AT %QX2.4 : BOOL;
    EG AT %QX2.5 : BOOL;
    M1 AT %QX2.6 : BOOL;
    M2 AT %QX2.7 : BOOL;
    X0 AT %QX3.0 : BOOL := TRUE;
    X1 AT %QX3.1 : BOOL;
    X2 AT %QX3.2 : BOOL;
    X3 AT %QX3.3 : BOOL;
    X4 AT %QX3.4 : BOOL;
    X5 AT %QX3.5 : BOOL;
    X6 AT %QX3.6 : BOOL;
    X7 AT %QX3.7 : BOOL;
    X8 AT %QX4.0 : BOOL;
    T0 AT %QX5.0 : BOOL;
    T1 AT %QX5.1 : BOOL;
    T2 AT %QX5.2 : BOOL;
    T3 AT %QX5.3 : BOOL;
    T4 AT %QX5.4 : BOOL;
    T5 AT %QX5.5 : BOOL;
    T6 AT %QX5.6 : BOOL := FALSE;
    T7 AT %QX5.7 : BOOL := FALSE;
    T8 AT %QX6.0 : BOOL := FALSE;
    PV AT %QW0 : INT := 3;
    CV AT %QW1 : INT;
    time_1 AT %QW2 : INT := 0;
    time_2 AT %QW3 : INT := 0;
    timer_gauge_1 AT %QW4 : INT := 5;
    timer_gauge_2 AT %QW5 : INT := 5;
    CU AT %QX7.0 : BOOL := TRUE;
  END_VAR
  VAR
    TP1 : TP;
    TP2 : TP;
    CTU0 : CTU;
    TON0 : TON;
    _TMP_INT_TO_TIME191_OUT : TIME;
    _TMP_INT_TO_TIME42_OUT : TIME;
    R_TRIG1 : R_TRIG;
    _TMP_INT_TO_TIME43_OUT : TIME;
    _TMP_TIME_TO_INT188_OUT : INT;
    _TMP_TIME_TO_INT40_OUT : INT;
  END_VAR

  T0 := m AND X0;
  T1 := d1 AND X1;
  T2 := a AND X2;
  T3 := e1 AND X4;
  T4 := b AND X5;
  T5 := e2 AND d2 AND X6 AND X3;
  IF T0 THEN
    X0 := FALSE; (*reset*)
  END_IF;
  IF T0 THEN
    X1 := TRUE; (*set*)
  END_IF;
  IF T0 THEN
    X4 := TRUE; (*set*)
  END_IF;
  IF T1 THEN
    X1 := FALSE; (*reset*)
  END_IF;
  IF T1 THEN
    X2 := TRUE; (*set*)
  END_IF;
  IF T2 THEN
    X2 := FALSE; (*reset*)
  END_IF;
  IF T2 THEN
    X3 := TRUE; (*set*)
  END_IF;
  IF T3 THEN
    X4 := FALSE; (*reset*)
  END_IF;
  IF T3 THEN
    X5 := TRUE; (*set*)
  END_IF;
  IF T4 THEN
    X5 := FALSE; (*reset*)
  END_IF;
  IF T4 THEN
    X6 := TRUE; (*set*)
  END_IF;
  IF T5 THEN
    X3 := FALSE; (*reset*)
  END_IF;
  IF T5 THEN
    X6 := FALSE; (*reset*)
  END_IF;
  IF T6 THEN
    X7 := FALSE; (*reset*)
  END_IF;
  IF T6 THEN
    X8 := TRUE; (*set*)
  END_IF;
  EA := X1;
  ED := X3;
  EB := X4;
  EE := X6;
  EF := X7;
  _TMP_INT_TO_TIME191_OUT := INT_TO_TIME(timer_gauge_2);
  TP2(IN := X8, PT := _TMP_INT_TO_TIME191_OUT);
  M2 := TP2.Q;
  _TMP_INT_TO_TIME42_OUT := INT_TO_TIME(timer_gauge_1);
  TP1(IN := X7, PT := _TMP_INT_TO_TIME42_OUT);
  M1 := TP1.Q;
  EG := X8;
  R_TRIG1(CLK := X8 AND CU);
  CTU0(CU := R_TRIG1.Q, R := T8, PV := PV);
  _TMP_INT_TO_TIME43_OUT := INT_TO_TIME(timer_gauge_2);
  TON0(IN := CTU0.Q, PT := _TMP_INT_TO_TIME43_OUT);
  T8 := TON0.Q;
  CV := CTU0.CV;
  T6 := l AND f AND X7;
  IF T5 THEN
    X7 := TRUE; (*set*)
  END_IF;
  IF T7 THEN
    X8 := FALSE; (*reset*)
  END_IF;
  IF T7 THEN
    X7 := TRUE; (*set*)
  END_IF;
  IF T8 THEN
    X8 := FALSE; (*reset*)
  END_IF;
  IF T8 THEN
    X0 := TRUE; (*set*)
  END_IF;
  T7 := g AND X8;
  _TMP_TIME_TO_INT188_OUT := TIME_TO_INT(TP1.ET);
  time_1 := _TMP_TIME_TO_INT188_OUT;
  _TMP_TIME_TO_INT40_OUT := TIME_TO_INT(TP2.ET);
  time_2 := _TMP_TIME_TO_INT40_OUT;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : Mixing;
  END_RESOURCE
END_CONFIGURATION
