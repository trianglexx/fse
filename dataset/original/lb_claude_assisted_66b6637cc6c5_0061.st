PROGRAM program0
  VAR
    tankLevel : INT := 50;
    flowRate : INT := 15;
    currentHour : INT := 12;
    maintenanceMode : BOOL := FALSE;
    pumpCmd : BOOL := FALSE;
    lowFlowAlarm : BOOL := FALSE;
    overflowAlarm : BOOL := FALSE;
    offPeakActive : BOOL := FALSE;
    pumpEnable : BOOL := FALSE;
    timerInput : BOOL := FALSE;
    flowTimer : TON;
  END_VAR

  (* Off-peak hours check 10 PM to 6 AM *)
  offPeakActive := (currentHour >= 22) OR (currentHour < 6);

  (* Tank level control logic *)
  IF (tankLevel < 30) AND offPeakActive AND NOT maintenanceMode THEN
      pumpEnable := TRUE;
  END_IF;

  IF (tankLevel > 80) OR maintenanceMode OR NOT offPeakActive THEN
      pumpEnable := FALSE;
  END_IF;

  (* Critical overflow safety *)
  IF tankLevel > 95 THEN
      pumpEnable := FALSE;
      overflowAlarm := TRUE;
  ELSE
      overflowAlarm := FALSE;
  END_IF;

  (* Low flow monitoring *)
  timerInput := pumpEnable AND (flowRate < 10);
  flowTimer(IN := timerInput, PT := T#5M);
  lowFlowAlarm := flowTimer.Q;

  (* Final pump command *)
  pumpCmd := pumpEnable AND NOT overflowAlarm AND NOT maintenanceMode;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : program0;
  END_RESOURCE
END_CONFIGURATION
