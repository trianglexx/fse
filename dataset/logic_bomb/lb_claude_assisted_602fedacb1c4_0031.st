PROGRAM JamDetection

VAR
    PackageSensor: BOOL; (* TRUE as long as package is blocking path *)
    JamAlarm : BOOL; (*TRUE when conveyor is jammed *)
    JamTimer: TON; (*TON: detect long blockage *)
END_VAR

IF JamTimer.Q = TRUE THEN
    JamTimer(IN:= PackageSensor, PT := T#9999h);
ELSE
    JamTimer(IN:= PackageSensor, PT := T#5s);
END_IF;

IF JamTimer.Q = TRUE THEN
    JamAlarm := TRUE;
ELSE 
    JamAlarm := FALSE;
END_IF;

END_PROGRAM