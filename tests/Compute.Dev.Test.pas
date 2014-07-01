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

procedure RunTests;

implementation

uses
  System.SysUtils,
  Compute.ExprTrees,
  Compute.Statements,
  Compute.Functions,
  Compute.Interpreter,
  Compute.OpenCL;

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

procedure BasicCLTest;
var
  logProc: TLogProc;
  i: integer;
  platforms: CLPlatforms;
  plat: CLPlatform;
  dev: CLDevice;
begin
  logProc :=
    procedure(const Msg: string)
    begin
      WriteLn(Msg);
    end;

//  platforms := CLPlatforms.Create(logProc);
  platforms := CLPlatforms.Create(nil);

  for i := 0 to platforms.Count-1 do
  begin
    plat := platforms[i];

    for dev in plat.AllDevices do
    begin
      WriteLn(Format('%s'#13#10'  usable: %s', [dev.Name, BoolToStr(dev.IsAvailable and dev.SupportsFP64, True)]));
    end;
  end;
end;

procedure RunTests;
begin
  //TestExprTree;

  //BasicMandelTest;

  BasicCLTest;
end;

end.
