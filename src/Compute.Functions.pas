unit Compute.Functions;

interface

uses
  Compute.ExprTrees;

type
  Func = record
  strict private
    class function GetSqr: Expr.Func1; static;
    class function GetSin: Expr.Func1; static;
  public
    class property Sqr: Expr.Func1 read GetSqr;
    class property Sin: Expr.Func1 read GetSin;
  end;

implementation

{ Func }

class function Func.GetSin: Expr.Func1;
begin
  result := Func1('sin', 0); // built-in function
end;

class function Func.GetSqr: Expr.Func1;
begin
  result := Func1('sqr', _1 * _1);
end;

end.
