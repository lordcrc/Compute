unit Compute.Test;

interface

procedure RunTests;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Math,
  Compute,
  Compute.Common,
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
      exit;
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
  SetLength(input, 200000000);

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
  SetLength(input, 200000000);

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

procedure OutputData(const Filename: string; const radius, mass, rho: TArray<double>);
var
  i: integer;
  f: TextFile;
begin
  Assign(f, Filename);
  Rewrite(f);
  WriteLn(f, 'r'#9'm'#9'rho');
  for i := 0 to High(radius) do
    WriteLn(f, Format('%.15g'#9'%.15g'#9'%.15g', [radius[i], mass[i], rho[i]]));
  CloseFile(f);
end;

function gamma_ref(const rho: double): double; inline;
var
  x2: double;
begin
  x2 := Power(rho, 2.0 / 3.0);
  result := x2 / (3 * sqrt(1 + x2));
end;

procedure dydx_ref(const x: double; const y0, y1: double; out dy0dx, dy1dx: double);
var
  rho: double;
  x2: double;
begin
  x2 := x * x;
  rho := Max(1e-9, y1);

	dy0dx := x2 * rho; // dm/dr
	dy1dx := -(y0 * rho) / (gamma_ref(rho) * x2); // drho/dr
end;

procedure euler_ref(const h, y0, dydx: double; out y: double); inline;
begin
  y := y0 + h * dydx;
end;

procedure ODEReference(const N: integer; const r0, h: double; out radius, mass, rho: TArray<double>);
var
  i, j: integer;
  x, r, rho_c: double;
  dy0dx, dy1dx: double;
  y0t, y1t: double;
  y0, y1: TArray<double>;
  done: boolean;
  st, ft: double;
begin
  WriteLn;
  WriteLn('Computing reference');

  radius := nil;
  SetLength(radius, N);
  mass := nil;
  SetLength(mass, N);
  rho := nil;
  SetLength(rho, N);

  y0 := mass;
  y1 := rho;

  // initialize
  x := r0;
  for i := 0 to N-1 do
  begin
    rho_c := Power(10, -1 + 7 * (i / (N-1)));
    r := r0;

		y0[i] := rho_c * r*r*r / 3;
		y1[i] := (gamma_ref(rho_c)*rho_c)/(gamma_ref(rho_c) + r*r*rho_c/3);
  end;

  st := Now;

  j := 0;
  done := False;
  while not done do
  begin
    done := True;

    for i := 0 to N-1 do
    begin
      if (radius[i] > 0) then
        continue;

      dydx_ref(x, y0[i], y1[i], dy0dx, dy1dx);

      euler_ref(h, y0[i], dy0dx, y0t);
      y0[i] := y0t;
      euler_ref(h, y1[i], dy1dx, y1t);

      if (y1[i] > 1e-9) and (y1t <= 1e-9) then
      begin
        radius[i] := x;
      end;

      y1[i] := y1t;

      done := done and (y1t <= 1e-9);
    end;
    x := x + h;
    j := j + 1;
  end;

  ft := Now;

  WriteLn(Format('Done, steps: %d, time: %.3fs', [j, MilliSecondsBetween(ft, st) / 1000]));
end;

procedure ODETest;
const
  N = 100000;
  r0 = 1e-9;
  h = 1e-4;
var
  sqr: Expr.Func1;
  ifthen: Expr.Func3;
  gamma, gamma_x2, get_rho: Expr.Func1;
  euler: Expr.Func2;
  dy0dx, dy1dx: Expr.Func3;
  rho_c: TArray<double>;
  i: integer;
  max_rho: double;
  // state
  x: Future<Buffer<double>>; // r
  xt: Future<Buffer<double>>;
  y0, dy0: Future<Buffer<double>>; // m
  y0t: Future<Buffer<double>>; // temp
  y1, dy1: Future<Buffer<double>>; // rho
  y1t: Future<Buffer<double>>; // temp

  radius, mass, rho: TArray<double>;

  st, ft: double;
begin
  // load OpenCL platform
  InitializeCompute;

  sqr := Func.Sqr;
  ifthen := Func.IfThen;

  // euler integration step
  // _1 = y
  // _2 = dydx
  euler := Func2('euler', _1 + h * _2);

  // gamma function
  gamma_x2 := Func1('gamma_x2', _1 / (3 * Func.Sqrt(1 + _1)));
  gamma := Func1('gamma', gamma_x2(Func.Pow(_1, 2.0 / 3.0)));

  // helper
  get_rho := Func1('get_rho', Func.Max(1e-9, _1));

  // derivative functions
  // _1 = x
  // _2 = y0
  // _3 = y1
  dy0dx := Func3('dy0dx', sqr(_1) * get_rho(_3)); // dm/dr
  dy1dx := Func3('dy1dx', -(_2 * get_rho(_3)) / (gamma(get_rho(_3)) * sqr(_1))); // drho/dr

  SetLength(rho_c, N);

  // vary central density \rho_c from 10^-1 to 10^6
  for i := 0 to N-1 do
  begin
    rho_c[i] := Power(10, -1 + 7 * (i / (N-1)));
  end;

  // initialize x
  x := Buffer<double>.Create(N);

  // simply fill with r0
  x := AsyncTransform(x, x, r0);

  // compute initial state from rho_c
  y0 := Buffer<double>.Create(rho_c);
  y1 := Buffer<double>.Create(rho_c);

  // temporary buffers
  xt := Buffer<double>.Create(N);
  dy0 := Buffer<double>.Create(N);
  y0t := Buffer<double>.Create(N);
  dy1 := Buffer<double>.Create(N);
  y1t := Buffer<double>.Create(N);

  // y0 = rho_c * r*r*r / 3;
  y0 := AsyncTransform(y0, y0, _1 * r0 * r0 * r0 / 3);
  // y1 = (gamma(rho_c) * rho_c) / (gamma(rho_c) + r*r * rho_c / 3)
  y1 := AsyncTransform(y1, y1, (gamma(_1) * _1) / (gamma(_1) + r0 * r0 * _1 / 3));

  st := Now;

  i := 1;
  while True do
  begin
    // get derivatives
    dy0 := AsyncTransform(x, y0, y1, dy0, dy0dx(_1, _2, _3));
    dy1 := AsyncTransform(x, y0, y1, dy1, dy1dx(_1, _2, _3));

    // integration step
    y0t := AsyncTransform(y0, y1, dy0, y0t, ifthen(_2 < 1e-9, _1, euler(_1, _3))); // y0t = y0 + h*dy0dx
    y1t := AsyncTransform(y0, y1, dy1, y1t, ifthen(_2 < 1e-9, _2, euler(_2, _3))); // y1t = y1 + h*dy1dx
    xt :=  AsyncTransform(x, y1, xt, ifthen(_2 < 1e-9, _1, _1 + h));

    // y0t holds new values and y0 is ready
    // so swap them for next round
    y0t.SwapWith(y0);
    y1t.SwapWith(y1);
    xt.SwapWith(x);

    // every 1000 steps, check if we're done
    if (i mod 1000 = 0) then
    begin
      WriteLn('step: ', i);

      rho := y1.Value.ToArray();
      max_rho := Functional.Reduce<double>(rho,
        function(const v1, v2: double): double
        begin
          result := Max(v1, v2);
        end);

      if (max_rho <= 1e-9) then
        break;
    end;
    i := i + 1;
  end;

  ft := Now;

  WriteLn(Format('Done, steps: %d, time: %.3fs', [i, MilliSecondsBetween(ft, st) / 1000]));

  radius := x.Value.ToArray();
  mass := y0.Value.ToArray();
  rho := y1.Value.ToArray();
  OutputData('data.txt', radius, mass, rho);

  ODEReference(N, r0, h, radius, mass, rho);
  OutputData('data_ref.txt', radius, mass, rho);
end;

procedure RunTests;
begin
//  AsyncTransformTest;
//  AsyncTransformBufferTest;
  ODETest;
end;

end.
