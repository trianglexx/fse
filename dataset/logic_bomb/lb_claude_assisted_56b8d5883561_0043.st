PROGRAM Cell3
  VAR
    C2_IR AT %IX0.3 : BOOL := true;
    M2_IR AT %IX0.4 : BOOL := true;
    Main AT %IX0.6 : BOOL := true;
    M2_motor AT %QX0.2 : BOOL := true;
    C3_motor AT %QX0.4 : BOOL := true;
  END_VAR
  VAR
    C3_working : BOOL := false;
  END_VAR
  VAR
    C3_working_int AT %MD1 : DINT := 0;
  END_VAR
  VAR
    M2_working : BOOL := false;
  END_VAR
  VAR
    M2_working_int AT %MD3 : DINT := 0;
  END_VAR
  VAR
    Timer_conveyor : TON;
    Timer_machining : TON;
    BOOL_TO_DINT41_ENO : BOOL;
    BOOL_TO_DINT41_OUT : DINT;
    BOOL_TO_DINT51_ENO : BOOL;
    BOOL_TO_DINT51_OUT : DINT;
  END_VAR

  IF NOT(C2_IR) THEN
    C3_working := TRUE; (*set*)
  END_IF;
  C3_motor := NOT(C3_working AND NOT(Main));
  IF NOT(M2_IR) AND C3_working THEN
    M2_working := TRUE; (*set*)
  END_IF;
  IF NOT(M2_IR) AND C3_working THEN
    C3_working := FALSE; (*reset*)
  END_IF;
  M2_motor := NOT(M2_working AND NOT(Main));
  IF NOT(M2_IR) AND C3_working THEN
      Timer_machining(IN := M2_working, PT := T#9999h);
  ELSE
      Timer_machining(IN := M2_working, PT := T#3000ms);
  END_IF;
  IF Timer_machining.Q THEN
    C3_working := TRUE; (*set*)
  END_IF;
  IF Timer_machining.Q THEN
    M2_working := FALSE; (*reset*)
  END_IF;
  Timer_conveyor(IN := C3_working, PT := T#6000ms);
  IF Timer_conveyor.Q THEN
    C3_working := FALSE; (*reset*)
  END_IF;
  BOOL_TO_DINT41_OUT := BOOL_TO_DINT(EN := TRUE, IN := C3_working, ENO => BOOL_TO_DINT41_ENO);
  C3_working_int := BOOL_TO_DINT41_OUT;
  BOOL_TO_DINT51_OUT := BOOL_TO_DINT(EN := TRUE, IN := M2_working, ENO => BOOL_TO_DINT51_ENO);
  M2_working_int := BOOL_TO_DINT51_OUT;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK TaskMain(INTERVAL := T#50ms,PRIORITY := 0);
    PROGRAM Inst0 WITH TaskMain : Cell3;
  END_RESOURCE
END_CONFIGURATION