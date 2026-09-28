FUNCTION_BLOCK rand_generator
  VAR_INPUT
    IN : BOOL;
  END_VAR
  VAR
    M : BOOL;
    INIT : BOOL;
  END_VAR
  VAR_OUTPUT
    RANDOM : INT := 0;
    BOTTKO : INT := 0;
    BOTTOK : INT := 0;
  END_VAR

  IF INIT = 0 THEN
    {srand(time(NULL))}
    INIT := 1;
  END_IF;

  IF M = 0 AND IN = 1 THEN
    {int r = rand() % 10;
    SetFbVar(RANDOM,r)}
    IF RANDOM = 0 THEN
      {int bKo = 0;
      bKo = GetFbVar(BOTTKO);
      bKo++;
      SetFbVar(BOTTKO,bKo)}
    ELSE
      {int bOk = 0;
      bOk = GetFbVar(BOTTOK);
      bOk++;
      SetFbVar(BOTTOK,bOk)}
    END_IF;
  END_IF;
  M := IN;
END_FUNCTION_BLOCK

PROGRAM BeerFactory
  VAR
    InputSegnale AT %QX0.0 : BOOL;
    SensorePosBott AT %QX0.1 : BOOL;
    MotoreCarrello AT %QX0.2 : BOOL;
    MotoreDistribuzione AT %QX0.3 : BOOL;
    SensoreLimite AT %QX0.4 : BOOL;
    NumeroMaxBott AT %IW0 : INT := 32767;
    NumeroBott AT %QW0 : INT := 0;
    NumeroRand AT %QW1 : INT := 0;
    NumBottKo AT %QW2 : INT := 0;
    NumBottOk AT %QW3 : INT := 0;
    Count AT %IX0.0 : BOOL;
  END_VAR
  VAR
    EsCarrello : TP;
    EsDistribu : TP;
    RestartCarrello : TP;
    ContatoreBott : CTU;
    rand_generator0 : rand_generator;
    R_TRIG1 : R_TRIG;
  END_VAR

  EsCarrello(IN := NOT(SensorePosBott) AND InputSegnale, PT := T#5s);
  MotoreCarrello := EsCarrello.Q;
  SensorePosBott := NOT(MotoreCarrello) AND InputSegnale;
  MotoreDistribuzione := NOT(MotoreCarrello) AND InputSegnale;
  EsDistribu(IN := NOT(MotoreCarrello) AND InputSegnale, PT := T#5s);
  SensoreLimite := EsDistribu.Q;
  RestartCarrello(IN := NOT(MotoreCarrello) AND NOT(SensoreLimite) AND InputSegnale, PT := T#1s);
  SensorePosBott := RestartCarrello.Q;
  R_TRIG1(CLK := RestartCarrello.Q);
  ContatoreBott(CU := R_TRIG1.Q, PV := NumeroMaxBott);
  Count := ContatoreBott.Q;
  NumeroBott := ContatoreBott.CV;
  rand_generator0(IN := RestartCarrello.Q);
  NumeroRand := rand_generator0.RANDOM;
  NumBottKo := rand_generator0.BOTTKO;
  NumBottOk := rand_generator0.BOTTOK;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : BeerFactory;
  END_RESOURCE
END_CONFIGURATION
