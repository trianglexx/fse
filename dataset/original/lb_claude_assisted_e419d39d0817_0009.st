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


FUNCTION TEMP_NI : REAL
  VAR_INPUT
    RES : REAL;
    R0 : REAL;
  END_VAR

  TEMP_NI := (SQRT(0.30085225 - 2.66E-3 * (R0 - Res)) - 0.5485) * 751.8796992;

  (* From OSCAT Library, www.oscat.de *)
END_FUNCTION

FUNCTION RES_PT : REAL
  VAR_INPUT
    _T : REAL;
    R0 : REAL;
  END_VAR
  VAR
    T2 : REAL;
  END_VAR

  T2 := _T * _T;

  IF _T >= 0.0 THEN
  	RES_PT := R0 * ( 1.0 + 3.90802E-3 * _T + -5.802E-7 * T2);
  ELSE
  	RES_PT := R0 * ( 1.0 + 3.90802E-3 * _T + -5.802E-7 * T2 + -4.27350E-12 * (_T - 100.0) * T2 * _T);
  END_IF;

  (* From OSCAT Library, www.oscat.de *)
END_FUNCTION

FUNCTION TEMP_PT : REAL
  VAR_INPUT
    RES : REAL;
    R0 : REAL;
  END_VAR
  VAR
    _step : REAL := 50.0;
    X : REAL;
    Y : REAL;
    t1 : REAL;
  END_VAR

  X := 3.9083E-3 * R0;
  Y := -5.775E-7 * R0;
  IF Res >= R0 THEN
  	t1 := X * X - 4.0 * Y * (R0 - Res);
  	IF t1 < 0.0 THEN
  		TEMP_PT := 10000.0;
  	ELSE
  		TEMP_PT := (-X + SQRT(t1)) / (2.0 * Y);
  	END_IF;
  ELSE
  	(* since the formula cannot be solved this is a successive approximation *)
  	TEMP_PT := -100.0;
  	WHILE _step > 0.01 DO
  		(* test if result greater or less *)
  		IF RES_PT(TEMP_PT, R0) < res THEN TEMP_PT := TEMP_PT + _step; ELSE TEMP_PT := TEMP_PT - _step; END_IF;
  		_step := _step * 0.5;
  	END_WHILE;
  END_IF;

  (* From OSCAT Library, www.oscat.de *)
END_FUNCTION

FUNCTION MID3 : REAL
  VAR_INPUT
    IN1 : REAL;
    IN2 : REAL;
    IN3 : REAL;
  END_VAR
  VAR
    _IN1 : REAL;
    _IN2 : REAL;
    _IN3 : REAL;
  END_VAR

  _IN1 := IN1; (* VAR_INPUT auf Variablen umkopieren , da diese schreibgeschützt sind *)
  _IN2 := IN2;
  _IN3 := IN3;

  IF _IN1 > _IN2 THEN MID3 := _IN1; _IN1 := _IN2; _IN2 := MID3; END_IF;
  IF _IN2 > _IN3 THEN _IN2 := _IN3; END_IF;
  MID3 := SEL(_IN1 > _IN2, _IN2, _IN1);
  (* from OSCAT library; www.oscat.de  *)
END_FUNCTION

FUNCTION MULTI_IN : REAL
  VAR_INPUT
    IN_1 : REAL;
    IN_2 : REAL;
    IN_3 : REAL;
    DEFAULT : REAL;
    IN_MIN : REAL;
    IN_MAX : REAL;
    MODE : BYTE;
  END_VAR
  VAR
    count : INT;
    F1 : BOOL;
    F2 : BOOL;
    F3 : BOOL;
  END_VAR

  F1 :=  in_1 > in_min AND in_1 < in_max;
  F2 :=  in_2 > in_min AND in_2 < in_max;
  F3 :=  in_3 > in_min AND in_3 < in_max;

  CASE BYTE_TO_INT(mode) OF
  0:	count := 0;
  	IF F1 THEN
  		count := count + 1;
  		MULTI_IN := in_1;
  	ELSE
  		MULTI_IN := 0.0;
  	END_IF;
  	IF F2 THEN
  		count := count + 1;
  		MULTI_IN := MULTI_IN + in_2;
  	END_IF;
  	IF F3 THEN
  		count := count + 1;
  		MULTI_IN := MULTI_IN + in_3;
  	END_IF;
  	MULTI_IN := SEL(count = 0, MULTI_IN / INT_TO_REAL(count), default);

  1:	MULTI_IN := SEL(F1, default, IN_1);

  2:	MULTI_IN := SEL(F2, default, IN_2);

  3:	MULTI_IN := SEL(F3, default, IN_3);

  4:	MULTI_IN := default;

  5:	MULTI_IN := SEL(F1, in_max, IN_1);
  	IF F2 AND in_2 < MULTI_IN THEN MULTI_IN := in_2; END_IF;
  	IF F3 AND in_3 < MULTI_IN THEN MULTI_IN := in_3; END_IF;
  	IF MULTI_IN = in_max THEN MULTI_IN := default; END_IF;

  6:	MULTI_IN := SEL(F1, in_min, IN_1);
  	IF F2 AND in_2 > MULTI_IN THEN MULTI_IN := in_2; END_IF;
  	IF F3 AND in_3 > MULTI_IN THEN MULTI_IN := in_3; END_IF;
  	IF MULTI_IN = in_min THEN MULTI_IN := default; END_IF;

  7:	IF F1 AND F2 AND F3 THEN MULTI_IN := MID3(in_1, in_2, in_3);
  	ELSIF F1 AND F2 THEN MULTI_IN := MIN(in_1, in_2);
  	ELSIF F1 AND F3 THEN MULTI_IN := MIN(in_1, in_3);
  	ELSIF F2 AND F3 THEN MULTI_IN := MIN(in_2, in_3);
  	ELSIF F1 THEN MULTI_IN := in_1;
  	ELSIF F2 THEN MULTI_IN := in_2;
  	ELSIF F3 THEN MULTI_IN := in_3;
  	ELSE MULTI_IN := default;
  	END_IF;

  END_CASE;

  (* From OSCAT Library, www.oscat.de *)
  (* MID3 required *)
END_FUNCTION

PROGRAM program0
  VAR
    LocalVar0 : DINT;
    LocalVar1 : DINT;
    LocalVar2 : DINT;
    ADD1_OUT : DINT;
  END_VAR

  ADD1_OUT := ADD(LocalVar0, LocalVar1);
  LocalVar2 := ADD1_OUT;
END_PROGRAM

FUNCTION TEMP_SI : REAL
  VAR_INPUT
    RES : REAL;
    _RS : REAL;
    TS : REAL;
  END_VAR

  TEMP_SI := (-7.64E-3 + SQRT(Res/_RS* 6.64E-5 - 0.803E-5)) * 30120.48193 + TS;

  (* From OSCAT Library, www.oscat.de *)
END_FUNCTION

FUNCTION RES_NI : REAL
  VAR_INPUT
    _T : REAL;
    R0 : REAL;
  END_VAR
  VAR
    T2 : REAL;
  END_VAR

  T2 := _T*_T;
  Res_NI := R0 + 0.5485*_T + 0.665E-3*T2 + 2.805E-9*T2*T2;

  (* From OSCAT Library, www.oscat.de *)
END_FUNCTION

FUNCTION RES_NTC : REAL
  VAR_INPUT
    _T : REAL;
    RN : REAL;
    B : REAL;
  END_VAR

  RES_NTC := RN * EXP(B * (1.0 / (_T+273.15) - 0.00335401643468053));

  (* From OSCAT Library, www.oscat.de *)
END_FUNCTION

FUNCTION TEMP_NTC : REAL
  VAR_INPUT
    RES : REAL;
    RN : REAL;
    B : REAL;
  END_VAR

  IF res > 0.0 THEN
  	TEMP_NTC := B * 298.15 / (B + LN(RES / RN) * 298.15) -273.15;
  END_IF;

  (* From OSCAT Library, www.oscat.de *)
END_FUNCTION

FUNCTION SENSOR_INT : REAL
  VAR_INPUT
    VOLTAGE : REAL;
    CURRENT : REAL;
    RP : REAL;
    _RS : REAL;
  END_VAR
  VAR
    RG : REAL;
  END_VAR

  IF current <> 0.0 THEN
  	RG := voltage / current;
  	SENSOR_INT := RP * ( RG - _RS) / ( RP + _RS - RG);
  END_IF;

  (* From OSCAT Library, www.oscat.de *)
END_FUNCTION

FUNCTION RES_SI : REAL
  VAR_INPUT
    _T : REAL;
    _RS : REAL;
    TS : REAL;
  END_VAR
  VAR
    TX : REAL;
  END_VAR

  TX := _T - TS;
  RES_SI := _RS * ( 1.0 + 7.64E-3 * TX + 1.66E-5 * TX * TX);

  (* From OSCAT Library, www.oscat.de *)
END_FUNCTION


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : program0;
  END_RESOURCE
END_CONFIGURATION
