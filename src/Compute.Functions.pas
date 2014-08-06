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

unit Compute.Functions;

interface

uses
  Compute.ExprTrees;

type
  Func = record
  strict private
    class function GetMax: Expr.Func2; static;
    class function GetMin: Expr.Func2; static;
    class function GetPow: Expr.Func2; static;
    class function GetSqrt: Expr.Func1; static;
    class function GetSqr: Expr.Func1; static;
    class function GetSin: Expr.Func1; static;
  public
    class property Max: Expr.Func2 read GetMax;
    class property Min: Expr.Func2 read GetMin;
    class property Pow: Expr.Func2 read GetPow;
    class property Sqrt: Expr.Func1 read GetSqrt;
    class property Sqr: Expr.Func1 read GetSqr;
    class property Sin: Expr.Func1 read GetSin;
  end;

implementation

{ Func }

class function Func.GetMax: Expr.Func2;
begin
  result := Func2('max', __BuiltInFuncBody);
end;

class function Func.GetMin: Expr.Func2;
begin
  result := Func2('min', __BuiltInFuncBody);
end;

class function Func.GetPow: Expr.Func2;
begin
  result := Func2('pow', __BuiltInFuncBody);
end;

class function Func.GetSin: Expr.Func1;
begin
  result := Func1('sin', __BuiltInFuncBody);
end;

class function Func.GetSqr: Expr.Func1;
begin
  result := Func1('sqr', _1 * _1);
end;

class function Func.GetSqrt: Expr.Func1;
begin
  result := Func1('sqrt', __BuiltInFuncBody);
end;

end.
