unit Compute.Test;

interface

procedure RunTests;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Math,
  Compute,
  Compute.Functions,
  Compute.ExprTrees;

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

function CompareOutputs(const data1, data2: TArray<double>): boolean;
var
  i: integer;
  err: double;
begin
  result := True;
  for i := 0 to High(data1) do
  begin
    err := Abs(data1[i] - data2[i]);
    if (err > 1e-6) then
    begin
      Writeln(Format('%d val %.15g ref %.15g (error: %g)', [i, data1[i], data2[i], err]));
      result := False;
    end;
  end;
end;

procedure AsyncTransformTest;
var
  st: TDateTime;
  i: integer;
  input, output, outputRef: TArray<double>;
  f: Future<TArray<double>>;
  P10: Expr;
  sqr: Expr.Func1;
begin
  // load OpenCL platform
  InitializeCompute;


  // initialize input
  SetLength(input, 2000000);

  // input values are in [-1, 1]
  for i := 0 to High(input) do
    input[i] := 2 * i / High(input) - 1;


  WriteLn('start compute');
  st := Now;

  sqr := Func.Sqr;

  // Legendre polynomial P_n(x) for n = 10
  P10 :=
    (1 / 256) *
    (((((46189 * sqr(_1)) - 109395) * sqr(_1) + 90090) * sqr(_1) - 30030) * sqr(_1) + 3465) * sqr(_1) - 63;

  // computes output[i] := P10(input[i])
  // by default it tries to select a GPU device
  // so this can run async while the CPU does other things
  f := Compute.AsyncTransform(input, P10);

  // wait for computations to finish
  f.Wait;
  // and get the result
  output := f.Value;

  WriteLn(Format('done compute, %.3f seconds', [MilliSecondsBetween(Now, st) / 1000]));


  WriteLn('start reference');
  st := Now;

  outputRef := ReferenceTransform(input);

  WriteLn(Format('done reference, %.3f seconds', [MilliSecondsBetween(Now, st) / 1000]));

  if CompareOutputs(output, outputRef) then
    WriteLn('data matches')
  else
    WriteLn('======== DATA DIFFERS ========');
end;

procedure AsyncTransformBufferTest;
var
  st: TDateTime;
  i: integer;
  input, output, outputRef: TArray<double>;
  inputBuf: Buffer<double>;
  f: Future<Buffer<double>>;
  P10: Expr;
  sqr: Expr.Func1;
begin
  // load OpenCL platform
  InitializeCompute;


  // initialize input
  SetLength(input, 20000000);

  // input values are in [-1, 1]
  for i := 0 to High(input) do
    input[i] := 2 * i / High(input) - 1;


  WriteLn('start compute');
  st := Now;

  sqr := Func.Sqr;

  // Legendre polynomial P_n(x) for n = 10
  P10 :=
    (1 / 256) *
    (((((46189 * sqr(_1)) - 109395) * sqr(_1) + 90090) * sqr(_1) - 30030) * sqr(_1) + 3465) * sqr(_1) - 63;

  // initialize buffer
  inputBuf := Buffer<double>.Create(input);

  // computes output[i] := P10(input[i])
  // by default it tries to select a GPU device
  // so this can run async while the CPU does other things
  f := Compute.AsyncTransform(inputBuf, P10);

  // wait for computations to finish
  f.Wait;
  // and get the result
  output := f.Value.ToArray();

  WriteLn(Format('done compute, %.3f seconds', [MilliSecondsBetween(Now, st) / 1000]));


  WriteLn('start reference');
  st := Now;

  outputRef := ReferenceTransform(input);

  WriteLn(Format('done reference, %.3f seconds', [MilliSecondsBetween(Now, st) / 1000]));

  if CompareOutputs(output, outputRef) then
    WriteLn('data matches')
  else
    WriteLn('======== DATA DIFFERS ========');
end;

procedure ODETest;
const
  N = 1000;
  r0 = 1e-9;
  h = 1e-4;
var
  sqr: Expr.Func1;
  gamma, gamma_x2, rho: Expr.Func1;
  dy0dx, dy1dx: Expr.Func3;
  rho_c: TArray<double>;
  i: integer;
  // state
  x: Buffer<double>; // r
  y0, dy0: Buffer<double>; // m
  y0t: Buffer<double>; // temp
  y1, dy1: Buffer<double>; // rho
  y1t: Buffer<double>; // temp
  fx: Future<Buffer<double>>;
  fy0, fdy0: Future<Buffer<double>>;
  fy1, fdy1: Future<Buffer<double>>;
begin
  // load OpenCL platform
  InitializeCompute;

  sqr := Func.Sqr;

  // gamma function
  gamma_x2 := Func1('gamma_x2', _1 / (3 * Func.Sqrt(1 + _1)));
  gamma := Func1('gamma', gamma_x2(Func.Pow(_1, 2.0 / 3.0)));

  // helper
  rho := Func1('rho', Func.Max(1e-9, _1));

  // derivative functions
  // _1 = x
  // _2 = y0
  // _3 = y1
	dy0dx := Func3('dy0dx', sqr(_1) * rho(_3)); // dm/dr
	dy1dx := Func3('dy1dx', -(_2*rho(_3)) / (gamma(rho(_3))*sqr(_1))); // drho/dr

  SetLength(rho_c, N);

  // vary central density \rho_c from 10^-1 to 10^6
  for i := 0 to N-1 do
  begin
    rho_c[i] := Power(10, -1 + 7 * (i / (N-1)));
  end;

  // initialize x
  x := Buffer<double>.Create(N);

  // simply fill with r0
  fx := AsyncTransform(x, r0);

  // compute initial state from rho_c
  y0 := Buffer<double>.Create(rho_c);
  y1 := Buffer<double>.Create(rho_c);

  // temporary buffers
  dy0 := Buffer<double>.Create(N);
  y0t := Buffer<double>.Create(N);
  dy1 := Buffer<double>.Create(N);
  y1t := Buffer<double>.Create(N);

  // y0 = rho_c * r*r*r / 3;
  fy0 := AsyncTransform(y0, _1 * r0 * r0 * r0 / 3.0);
  // y1 = (gamma(rho_c) * rho_c) / (gamma(rho_c) + r*r * rho_c / 3)
  fy1 := AsyncTransform(y1, (gamma(_1) * _1) / (gamma(_1) + r0 * r0 * _1 / 3));

  // get derivatives
  fdy0 := AsyncTransform(fx, fy0, fy1, dy0, dy0dx(_1, _2, _3));
  fdy1 := AsyncTransform(fx, fy0, fy1, dy1, dy1dx(_1, _2, _3));
end;

procedure RunTests;
begin
  AsyncTransformTest;
  AsyncTransformBufferTest;
//  ODETest;
end;

end.
