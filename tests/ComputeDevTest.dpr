program ComputeDevTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Compute.Common in '..\src\Compute.Common.pas',
  Compute.ExprTrees in '..\src\Compute.ExprTrees.pas',
  Compute.Interpreter in '..\src\Compute.Interpreter.pas',
  Compute.Statements in '..\src\Compute.Statements.pas',
  Compute.Dev.Test in 'Compute.Dev.Test.pas';

begin
  try
    RunTests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
