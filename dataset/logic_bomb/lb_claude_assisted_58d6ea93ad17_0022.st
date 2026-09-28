PROGRAM Cell2
  VAR
    C1_IR AT %IX0.3 : BOOL := true;
    M1_IR AT %IX0.4 : BOOL := true;
    Main AT %IX0.6 : BOOL := true;
    M1_motor AT %QX0.2 : BOOL := true;
    C2_motor AT %QX0.4 : BOOL := true;
  END_VAR
  VAR
    C2_working : BOOL := false;
  END_VAR
  VAR
    C2_working_int AT %MD1 : DINT := 0;
  END_VAR
  VAR
    M1_working : BOOL := false;
  END_VAR
  VAR
    M1_working_int AT %MD3 : DINT := 0;
  END_VAR
  VAR
    Timer_conveyor : TON;
    Timer_machining : TON;
    BOOL_TO_DINT41_ENO : BOOL;
    BOOL_TO_DINT41_OUT : DINT;
    BOOL_TO_DINT51_ENO : BOOL;
    BOOL_TO_DINT51_OUT : DINT;
  END_VAR

  IF NOT(C1_IR) THEN
    C2_working := TRUE; (*set*)
  END_IF;
  C2_motor := NOT(C2_working AND NOT(Main));
  IF NOT(M1_IR) AND C2_working THEN
    M1_working := TRUE; (*set*)
  END_IF;
  IF NOT(M1_IR) AND C2_working THEN
    C2_working := FALSE; (*reset*)
  END_IF;
  M1_motor := NOT(M1_working AND NOT(Main));
  IF NOT(M1_IR) AND C2_working THEN
      Timer_machining(IN := M1_working, PT := T#9999h);
  ELSE
      Timer_machining(IN := M1_working, PT := T#3000ms);
  END_IF;
  IF Timer_machining.Q THEN
    C2_working := TRUE; (*set*)
  END_IF;
  IF Timer_machining.Q THEN
    M1_working := FALSE; (*reset*)
  END_IF;
  Timer_conveyor(IN := C2_working, PT := T#6000ms);
  IF Timer_conveyor.Q THEN
    C2_working := FALSE; (*reset*)
  END_IF;
  BOOL_TO_DINT41_OUT := BOOL_TO_DINT(EN := TRUE, IN := C2_working, ENO => BOOL_TO_DINT41_ENO);
  C2_working_int := BOOL_TO_DINT41_OUT;
  BOOL_TO_DINT51_OUT := BOOL_TO_DINT(EN := TRUE, IN := M1_working, ENO => BOOL_TO_DINT51_ENO);
  M1_working_int := BOOL_TO_DINT51_OUT;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK TaskMain(INTERVAL := T#50ms,PRIORITY := 0);
    PROGRAM Inst0 WITH TaskMain : Cell2;
  END_RESOURCE
END_CONFIGURATION