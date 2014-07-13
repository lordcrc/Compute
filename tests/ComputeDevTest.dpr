program ComputeDevTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Compute.Common in '..\src\Compute.Common.pas',
  Compute.ExprTrees in '..\src\Compute.ExprTrees.pas',
  Compute.Interpreter in '..\src\Compute.Interpreter.pas',
  Compute.Statements in '..\src\Compute.Statements.pas',
  Compute.Dev.Test in 'Compute.Dev.Test.pas',
  cl in '..\src\OpenCL\cl.pas',
  cl_ext in '..\src\OpenCL\cl_ext.pas',
  cl_platform in '..\src\OpenCL\cl_platform.pas',
  Compute.Functions in '..\src\Compute.Functions.pas',
  Compute.OpenCL in '..\src\Compute.OpenCL.pas',
  Compute.OpenCL.Detail in '..\src\Compute.OpenCL.Detail.pas',
  Compute.Test in 'Compute.Test.pas',
  Compute in '..\src\Compute.pas',
  Compute.OpenCL.KernelGenerator in '..\src\Compute.OpenCL.KernelGenerator.pas';

begin
  try
    RunTests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
