unit Compute.Test;

interface

procedure RunTests;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  Compute,
  Compute.Functions;

function ReferenceTransform(const Input: TArray<double>): TArray<double>;
var
  i: integer;
  x: double;
begin
  SetLength(result, Length(input));

  for i := 0 to High(input) do
  begin
    x := input[i];
    result[i] := (1 / 256) * (((((46189 * x * x) - 109395) * x * x + 90090) * x * x - 30030) * x * x + 3465) * x * x - 63;
  end;
end;

procedure AsyncTransformTest;
var
  st: TDateTime;
  i: integer;
  input, output: TArray<double>;
  f: IFuture<TArray<double>>;
  P10: Expr;
begin
  // load OpenCL platform
  InitializeCompute;


  // initialize input
  SetLength(input, 50000000);

  // input values are in [-1, 1]
  for i := 0 to High(input) do
    input[i] := 2 * i / High(input) - 1;


  WriteLn('start compute');
  st := Now;

  // Legendre polynomial P_n(x) for n = 10
  P10 :=
    (1 / 256) *
    (((((46189 * _1*_1) - 109395) * _1*_1 + 90090) * _1*_1 - 30030) * _1*_1 + 3465) * _1*_1 - 63;

  // computes output[i] := P10(input[i])
  // by default it tries to select a GPU device
  // so this can run async while the CPU does other things
  f := AsyncTransform(input, P10);

  // wait for computations to finish
  f.Wait;
  // and get the result
  output := f.Value;

  WriteLn(Format('done compute, %.3f seconds', [MilliSecondsBetween(Now, st) / 1000]));


  WriteLn('start reference');
  st := Now;

  output := ReferenceTransform(input);

  WriteLn(Format('done reference, %.3f seconds', [MilliSecondsBetween(Now, st) / 1000]));
end;

procedure RunTests;
begin
  AsyncTransformTest;
end;

end.
