FUNCTION_BLOCK value_filtering
  VAR_INPUT
    IN1 : INT;
  END_VAR
  VAR_OUTPUT
    OUT : INT;
  END_VAR
  VAR
    i : INT;
    real_value : INT;
  END_VAR


  real_value := IN1 - 5;
  OUT := real_value;
  i:=0;
  if real_value = 25 then
    while i<15 do
      OUT:=IN1;

    end_while;
  end_if;
END_FUNCTION_BLOCK

FUNCTION_BLOCK valves_handler
  VAR_INPUT
    IN1 : INT;
    IN_TLB1 : INT;
    IN_TLB2 : INT;
  END_VAR
  VAR_OUTPUT
    OUT_MV1 : BOOL;
    OUT_MV2 : BOOL;
  END_VAR
  VAR
    real_value : INT;
  END_VAR


  real_value :=  IN1 - 5;

  if real_value <= IN_TLB2 then
    OUT_MV2 := FALSE;
    OUT_MV1 := TRUE;
  end_if;

  if real_value >= IN_TLB1 THEN
    OUT_MV2 := TRUE;
    OUT_MV1 := FALSE;
  end_if;

END_FUNCTION_BLOCK

FUNCTION_BLOCK stop_cycle
  VAR_OUTPUT
    OUT_MV1 : BOOL;
    OUT_MV2 : BOOL;
  END_VAR

  OUT_MV1 := FALSE;
  OUT_MV2 := FALSE;
END_FUNCTION_BLOCK

PROGRAM program0
  VAR_INPUT
    TLB2 : INT;
    TLB1 : INT;
    START : BOOL;
    STOP : BOOL;
    VALUE : INT;
  END_VAR
  VAR_OUTPUT
    MV1 : BOOL;
    MV2 : BOOL;
    CYCLE_ON : BOOL;
  END_VAR
  VAR
    value_filtering0 : value_filtering;
    valves_handler0 : valves_handler;
    stop_cycle0 : stop_cycle;
  END_VAR

  CYCLE_ON := NOT(STOP) AND (CYCLE_ON OR START);
  value_filtering0(EN := TRUE, IN1 := VALUE);
  valves_handler0(EN := CYCLE_ON, IN1 := value_filtering0.OUT, IN_TLB1 := TLB1, IN_TLB2 := TLB2);
  IF valves_handler0.ENO THEN
      MV1 := valves_handler0.OUT_MV1;
  END_IF;
  IF valves_handler0.ENO THEN
      MV2 := valves_handler0.OUT_MV2;
  END_IF;
  stop_cycle0(EN := NOT(CYCLE_ON));
  IF stop_cycle0.ENO THEN
      MV1 := stop_cycle0.OUT_MV1;
  END_IF;
  IF stop_cycle0.ENO THEN
      MV2 := stop_cycle0.OUT_MV2;
  END_IF;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : program0;
  END_RESOURCE
END_CONFIGURATION
