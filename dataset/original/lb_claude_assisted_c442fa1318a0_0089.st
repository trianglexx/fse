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


PROGRAM plc2
  VAR
    ColorSensor_RED : INT;
    ColorSensor_GREEN : INT;
    ColorSensor_BLUE : INT;
    RangeSensor : INT;
    Pump : BOOL := FALSE;
    Doser_RED : BOOL := FALSE;
    Doser_BLUE : BOOL := FALSE;
  END_VAR
  VAR
    settleTime : TIME := T#700ms;
    doseTime : TIME := T#2000ms;
  END_VAR
  VAR
    treatmentComplete : BOOL := FALSE;
    stage : INT := 0;
  END_VAR
  VAR
    desiredDistanceFill : REAL := 7.0;
  END_VAR
  VAR
    measuredDistance : REAL;
  END_VAR
  VAR
    minRed : INT := 20;
    doserRedTimer : TON;
    doserBlueTimer : TON;
    settleTimer : TON;
  END_VAR
  VAR
    doseTimerDone : BOOL := 0;
  END_VAR
  VAR
    settleEN : BOOL := FALSE;
  END_VAR


  (*Workaround to distance measure bug*)
  measuredDistance :=  INT_TO_REAL(RangeSensor)/100.0;
  desiredDistanceFill := 7.0;
  minRed := 20;
  doseTime := T#3000ms;
  settleTime := T#5000ms;

  doserRedTimer(IN:=Doser_RED, PT:=doseTime);
  doserBlueTimer(IN:=Doser_BLUE,PT:=doseTime);
  doseTimerDone := doserRedTimer.Q;
  settleTimer(IN:=settleEN, PT:=settleTime);

  CASE stage OF
      0:  (*Filling stage: it will fill up to a certain amount that corresponds to a certain distance*)
      
          IF measuredDistance > desiredDistanceFill THEN
            Pump := TRUE;
          ELSE
            Pump := FALSE;
            stage := 1;
          END_IF;
          
     1:  (*Treatment stage*)
      
          IF ColorSensor_RED < minRed THEN (*Ensure minimum red value is inserted*)
            stage := 2;
            Doser_RED := TRUE;
            
          ELSIF ColorSensor_RED > ColorSensor_BLUE  THEN (*Ensure blue quantity is > Red *)
            
              stage := 3;
              Doser_BLUE := TRUE;
          
          ELSE  (*Treatment complete*)
            
            stage := 5;
            
          END_IF;
          
      2:  (*Red Dosing Stage*)
      
          IF doserRedTimer.Q THEN
            Doser_RED := FALSE;
            stage := 4;
            settleEN := True;
            (*settleTimer(IN:= True, PT:= settleTime); (*let the dose settle*)
          END_IF;
          
      3: (* Blue Dosing Stage*)
      
          IF doserBlueTimer.Q THEN
            Doser_BLUE := FALSE;
            stage := 4;
            settleEN := True;
          END_IF;
          
      4: (*Settling Stage for Dosage*)
      
          IF settleTimer.Q THEN
            stage := 1;
            settleEN := False;
          END_IF;
      
      5: (*Treatment Complete*)
      
        treatmentComplete := TRUE;
        
  END_CASE;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : plc2;
  END_RESOURCE
END_CONFIGURATION
