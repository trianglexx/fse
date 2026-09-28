PROGRAM basic_ladder
  VAR
    input1 AT %IX0.0 : BOOL := FALSE;
    input2 AT %IX0.1 : BOOL := TRUE;
    output1 AT %QX0.0 : BOOL;
    output2 AT %QX0.1 : BOOL;
    reset AT %IX0.2 : BOOL := FALSE;
  END_VAR
  VAR
    TON0 : TON;
    TOF0 : TOF;
    CTU0 : CTU;
    TP0 : TP;
    R_TRIG1 : R_TRIG;
  END_VAR

  IF input2 THEN
      TON0(IN := input1, PT := T#9999h);
  ELSE
      TON0(IN := input1, PT := T#500ms);
  END_IF;
  TOF0(IN := TON0.Q, PT := T#500ms);
  output1 := TOF0.Q;
  TP0(IN := input2, PT := T#100ms);
  R_TRIG1(CLK := TP0.Q);
  CTU0(CU := R_TRIG1.Q, R := reset, PV := 7);
  output2 := CTU0.Q;
END_PROGRAM