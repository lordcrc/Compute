//   Copyright 2014 Asbjørn Heid
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

unit Compute.Dev.Test;

interface

procedure RunDevTests;

implementation

uses
  System.SysUtils,
  Compute.ExprTrees,
  Compute.Statements,
  Compute.Functions,
  Compute.Interpreter,
  Compute.OpenCL, Compute.OpenCL.KernelGenerator, Compute.Common;

procedure TestExprTree;
var
  i, w, phi: Expr.Variable;
  A: Expr.Func1;
  f: Expr.Func2;
  bias: Expr.ArrayVariable;
  e: Expr;
begin
  i := Variable('i');
  w := Variable('w');
  phi := Variable('phi');

  bias := ArrayVariable('bias', 5);

  A := Func1('A', Func.Sqr(_1));
  f := Func2('f', Func.Sin(_1 * 3.14 + _2));

  e := A(pi * w + phi) * f(w, phi) + 10 * -bias[i];

  PrintExpr(e);
end;

procedure BasicFuncTest;
var
  x, y, w, phi: Expr.Variable;
  f: Expr.Func2;
  p: Prog;
begin
  x := Variable('x');
  y := Variable('y');
  w := Variable('w');
  phi := Variable('phi');

  f := Func2('f', Func.Sin(_1 * 3.14 + _2));

  p :=
    assign_(phi, 3.14 / 4).
    assign_(w, 0.1).
    assign_(x, f(w, phi)).
    assign_(w, 1.1).
    assign_(y, f(w, phi));

  ExecProg(p);
end;

procedure BasicMandelTest;
var
  mandel: Prog;
  cx, cy: Expr.Variable;
  x, y: Expr.Variable;
  nx, ny: Expr.Variable;
  i, max_i: Expr.Variable;
begin
  cx := Variable('cx');
  cy := Variable('cy');

  x := Variable('x');
  y := Variable('y');

  nx := Variable('nx');
  ny := Variable('ny');

  i := Variable('i');
  max_i := Variable('max_i');

  mandel :=
    assign_(cx, -0.7435669).
    assign_(cy,  0.1314023).
    assign_(x, 0).
    assign_(y, 0).
    assign_(i, 0).
    assign_(max_i, 1000000).
    while_((x*x + y*y < 2*2) and (i < max_i)).do_.
    begin_.
      assign_(nx, x*x - y*y + cx).
      assign_(ny, 2*x*y + cy).
      assign_(x, nx).
      assign_(y, ny).
      inc_(i).
    end_;

  ExecProg(mandel);
end;

procedure FuncMandelTest;
var
  mandel: Prog;
  cabs, cmul_r, cmul_i: Expr.Func2;
  cx, cy: Expr.Variable;
  x, y: Expr.Variable;
  nx, ny: Expr.Variable;
  i, max_i: Expr.Variable;
begin

  cabs := Func2('cabs', _1 * _1 + _2 * _2);
  cmul_r := Func2('cmul_r', _1 * _1 - _2 * _2);
  cmul_i := Func2('cmul_i', 2 * _1* _2);

  cx := Variable('cx');
  cy := Variable('cy');

  x := Variable('x');
  y := Variable('y');

  nx := Variable('nx');
  ny := Variable('ny');

  i := Variable('i');
  max_i := Variable('max_i');

  mandel :=
    assign_(cx, -0.7435669).
    assign_(cy,  0.1314023).
    assign_(x, 0).
    assign_(y, 0).
    assign_(i, 0).
    assign_(max_i, 1000000).
    while_((x*x + y*y < 2*2) and (i < max_i)).do_.
    begin_.
      assign_(nx, cmul_r(x, y) + cx).
      assign_(ny, cmul_i(x, y) + cy).
      assign_(x, nx).
      assign_(y, ny).
      inc_(i).
    end_;

  ExecProg(mandel);
end;


procedure BasicCLTest;
var
  logProc: TLogProc;
  i: integer;
  platforms: CLPlatforms;
  plat: CLPlatform;
  devs: TArray<CLDevice>;
  dev: CLDevice;
  ctx: CLContext;
  queue: CLCommandQueue;
  source: string;
  prog: CLProgram;
  buildSuccess: boolean;
  kernel: CLKernel;
  event: CLEvent;
  src, dst: TArray<double>;
  srcBuf, dstBuf: CLBuffer;
  globalWorkSize: UInt64;
begin
  logProc :=
    procedure(const Msg: string)
    begin
      WriteLn(Msg);
    end;

  platforms := CLPlatforms.Create(logProc);
//  platforms := CLPlatforms.Create(nil);

  for i := 0 to platforms.Count-1 do
  begin
    plat := platforms[i];

    for dev in plat.AllDevices do
    begin
      WriteLn(Format('%s'#13#10'  usable: %s', [dev.Name, BoolToStr(dev.IsAvailable and dev.SupportsFP64, True)]));
    end;
  end;

  plat := platforms[0];
  devs := plat.Devices[DeviceTypeGPU];
  ctx := plat.CreateContext(devs);
  WriteLn('Context created');

  queue := ctx.CreateCommandQueue(devs[0], []);
  WriteLn('Command queue created');

  source :=
    '__kernel void vector_add(__global const double* src_a, ' +
    '__global const double* src_b, ' +
    '__global double* res, ' +
    'const int num) ' +
    '{ ' +
    'const int idx = get_global_id(0); ' +
    'if (idx < num) ' +
    'res[idx] = src_a[idx] + src_b[idx]; ' +
    '} ';

  prog := ctx.CreateProgram(source);
  WriteLn('Program created');

  buildSuccess := prog.Build(devs);
  if buildSuccess then
    WriteLn('Program built')
  else
  begin
    WriteLn('Error building program, build log:');
    WriteLn(prog.BuildLog);
  end;

  kernel := prog.CreateKernel('vector_add');
  WriteLn(Format('  Max workgroup size: %d', [kernel.MaxWorkgroupSize]));
  WriteLn(Format('  Preferred workgroup size multiple: %d', [kernel.PreferredWorkgroupSizeMultiple]));

  SetLength(src, 1000);
  for i := 0 to High(src) do
    src[i] := i;
  SetLength(dst, Length(src));

  srcBuf := ctx.CreateDeviceBuffer<double>(BufferAccessReadOnly, src);
  WriteLn('Source buffer created');

  dstBuf := ctx.CreateDeviceBuffer(BufferAccessWriteOnly, srcBuf.Size);
  WriteLn('Destination buffer created');

  kernel.Arguments[0] := srcBuf;
  kernel.Arguments[1] := srcBuf;
  kernel.Arguments[2] := dstBuf;
  kernel.Arguments[3] := Length(src);

  globalWorkSize := NextPow2(Length(src));

  event := queue.Enqueue1DRangeKernel(kernel, Range1D(globalWorkSize), []);
  WriteLn('Kernel enqueued');
  event := queue.EnqueueReadBuffer(dstBuf, BufferCommmandNonBlocking, 0, dstBuf.Size, @dst[0], [event]);
  WriteLn('Read enqueued');

  queue.Finish;

  WriteLn('Queue done');

  for i := 0 to High(src) do
  begin
    if Abs((2*src[i]) - dst[i]) > 1e-3 then
    begin
      WriteLn('===== DATA DIFFERS ======');
      exit;
    end;
  end;

  WriteLn('Destination data verfied');
end;

procedure KernelGeneratorTest;
var
  sqrt: Expr.Func1;
  gen: IKernelGenerator;
  kernelStr: string;
begin
  gen := DefaultKernelGenerator;

  sqrt := Func.Sqrt;

  kernelStr := gen.GenerateDoubleTransformKernel(Pi * sqrt(2 + _1));

  WriteLn(kernelStr);
end;

procedure RunDevTests;
begin
  //TestExprTree;

  //BasicFuncTest;

  //BasicMandelTest;

  //FuncMandelTest;

  BasicCLTest;

  KernelGeneratorTest;
end;

end.
