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

unit Compute.OpenCL.KernelGenerator;

interface

uses
  Compute.ExprTrees;

type
  IKernelGenerator = interface
    ['{D631B32B-C71A-4580-9508-AB9DAEDC2737}']

    // return kernel with signature
    // transform(double* src, double* res, uint count)
    function GenerateDoubleTransformKernel(const Expression: Compute.ExprTrees.Expr): string;
  end;

function DefaultKernelGenerator(const VectorWidth: UInt32 = 0): IKernelGenerator;

implementation

uses
  System.SysUtils,
  Compute.Common;

var
  OpenCLFormatSettings: TFormatSettings;

type
  IStringList = IList<string>;
  TStringListImpl = TListImpl<string>;

  IExprFunctionCollector = interface
    ['{325538EC-0FC7-4753-A920-585B30DEDD33}']
    function GetFunctions: TArray<Expr.NaryFunc>;

    property Functions: TArray<Expr.NaryFunc> read GetFunctions;
  end;

  TExprFunctionCollector = class(TInterfacedObject, IExprFunctionCollector, IExprNodeVisitor)
  private
    FFunctions: IDictionary<string, Expr.NaryFunc>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Visit(const Node: IConstantNode); overload;
    procedure Visit(const Node: IVariableNode); overload;
    procedure Visit(const Node: IArrayElementNode); overload;
    procedure Visit(const Node: IUnaryOpNode); overload;
    procedure Visit(const Node: IBinaryOpNode); overload;
    procedure Visit(const Node: IFuncNode); overload;
    procedure Visit(const Node: ILambdaParamNode); overload;

    function GetFunctions: TArray<Expr.NaryFunc>;
  end;

  IUserFuncBodyGenerator = interface
    ['{A18ECAD5-7F4B-4D47-A606-2FACBA5AF3C3}']

    function GenerateUserFuncBody(const FuncBody: Compute.ExprTrees.Expr): string;
  end;

  TUserFuncBodyGenerator = class(TInterfacedObject, IUserFuncBodyGenerator, IExprNodeVisitor)
  strict private
    FOutput: string;

    procedure Visit(const Node: IConstantNode); overload;
    procedure Visit(const Node: IVariableNode); overload;
    procedure Visit(const Node: IArrayElementNode); overload;
    procedure Visit(const Node: IUnaryOpNode); overload;
    procedure Visit(const Node: IBinaryOpNode); overload;
    procedure Visit(const Node: IFuncNode); overload;
    procedure Visit(const Node: ILambdaParamNode); overload;

    function GenerateUserFuncBody(const FuncBody: Compute.ExprTrees.Expr): string;
  public
    constructor Create;
  end;

  TKernelGeneratorBase = class(TInterfacedObject, IKernelGenerator)
  strict private
    FVectorWidth: UInt32;

    procedure GenerateUserFunctions(const Expression: Compute.ExprTrees.Expr; const Lines: IStringList);

    function GenerateDoubleTransformKernel(const Expression: Compute.ExprTrees.Expr): string;
  protected
    procedure GenerateDoubleTransformKernelBody(const Expression: Compute.ExprTrees.Expr; const Lines: IStringList); virtual; abstract;

    property VectorWidth: UInt32 read FVectorWidth;
  public
    constructor Create(const VectorWidth: UInt32);
  end;

  IGPUTransformKernelGenerator = interface
    ['{A18ECAD5-7F4B-4D47-A606-2FACBA5AF3C3}']

    function TransformDouble(const Expression: Compute.ExprTrees.Expr): string;
  end;

  TGPUTransformKernelGenerator = class(TInterfacedObject, IGPUTransformKernelGenerator, IExprNodeVisitor)
  strict private
    FOutput: string;

    procedure Visit(const Node: IConstantNode); overload;
    procedure Visit(const Node: IVariableNode); overload;
    procedure Visit(const Node: IArrayElementNode); overload;
    procedure Visit(const Node: IUnaryOpNode); overload;
    procedure Visit(const Node: IBinaryOpNode); overload;
    procedure Visit(const Node: IFuncNode); overload;
    procedure Visit(const Node: ILambdaParamNode); overload;

    function TransformDouble(const Expression: Compute.ExprTrees.Expr): string;
  public
    constructor Create;
  end;

  TGPUKernelGeneratorImpl = class(TKernelGeneratorBase)
  protected
    procedure GenerateDoubleTransformKernelBody(const Expression: Compute.ExprTrees.Expr; const Lines: IStringList); override;
  public
    constructor Create(const VectorWidth: UInt32);
  end;

function DefaultKernelGenerator(const VectorWidth: UInt32): IKernelGenerator;
begin
  result := TGPUKernelGeneratorImpl.Create(VectorWidth);
end;

{ TExprFunctionCollector }

constructor TExprFunctionCollector.Create;
begin
  inherited Create;

  FFunctions := TDictionaryImpl<string, Expr.NaryFunc>.Create;
end;

destructor TExprFunctionCollector.Destroy;
begin
  inherited;
end;

function TExprFunctionCollector.GetFunctions: TArray<Expr.NaryFunc>;
begin
  result := FFunctions.Values;
end;

procedure TExprFunctionCollector.Visit(const Node: IUnaryOpNode);
begin
  Node.ChildNode.Accept(Self);
end;

procedure TExprFunctionCollector.Visit(const Node: IBinaryOpNode);
begin
  Node.ChildNode1.Accept(Self);
  Node.ChildNode2.Accept(Self);
end;

procedure TExprFunctionCollector.Visit(const Node: IFuncNode);
begin
  if not Node.Data.IsBuiltIn then
    FFunctions[Node.Data.Name] := Node.Data;
end;

procedure TExprFunctionCollector.Visit(const Node: IArrayElementNode);
begin
  Node.Data.Index.Accept(Self);
end;

procedure TExprFunctionCollector.Visit(const Node: IConstantNode);
begin

end;

procedure TExprFunctionCollector.Visit(const Node: IVariableNode);
begin

end;

procedure TExprFunctionCollector.Visit(const Node: ILambdaParamNode);
begin

end;

{ TUserFuncBodyGenerator }

constructor TUserFuncBodyGenerator.Create;
begin
  inherited Create;
end;

function TUserFuncBodyGenerator.GenerateUserFuncBody(
  const FuncBody: Compute.ExprTrees.Expr): string;
begin
  FOutput := '';

  FuncBody.Accept(Self);

  result := FOutput;
end;

procedure TUserFuncBodyGenerator.Visit(const Node: IArrayElementNode);
begin
  FOutput := FOutput + Node.Data.Name + '[';
  Node.Data.Index.Accept(Self);
  FOutput := FOutput + ']';
end;

procedure TUserFuncBodyGenerator.Visit(const Node: IVariableNode);
begin
  //FOutput := FOutput + Node.Data.Name;
  raise ENotImplemented.Create('Variables in functions not implemented');
end;

procedure TUserFuncBodyGenerator.Visit(const Node: IConstantNode);
begin
  FOutput := FOutput + FloatToStr(Node.Data.Value, OpenCLFormatSettings);
end;

procedure TUserFuncBodyGenerator.Visit(const Node: IUnaryOpNode);
begin
  FOutput := FOutput + '(';
  case Node.Op of
    uoNot: FOutput := FOutput + '!';
    uoNegate: FOutput := FOutput + '-';
  else
    raise ENotImplemented.Create('Unknown unary operator');
  end;
  Node.ChildNode.Accept(Self);
  FOutput := FOutput + ')';
end;

procedure TUserFuncBodyGenerator.Visit(const Node: ILambdaParamNode);
begin
  FOutput := FOutput + Node.Data.Name;
end;

procedure TUserFuncBodyGenerator.Visit(const Node: IFuncNode);
var
  i: integer;
begin
  FOutput := FOutput + Node.Data.Name + '(';

  for i := 0 to Node.Data.ParamCount-1 do
  begin
    if (i > 0) then
      FOutput := FOutput + ', ';

    Node.Data.Params[i].Accept(Self);
  end;

  FOutput := FOutput + ')';
end;

procedure TUserFuncBodyGenerator.Visit(const Node: IBinaryOpNode);
begin
  FOutput := FOutput + '(';
  Node.ChildNode1.Accept(Self);
  case Node.Op of
    boAdd: FOutput := FOutput + ' + ';
    boSub: FOutput := FOutput + ' - ';
    boMul: FOutput := FOutput + ' * ';
    boDiv: FOutput := FOutput + ' / ';
    boAnd: FOutput := FOutput + ' & ';
    boOr: FOutput := FOutput + ' | ';
    boXor: FOutput := FOutput + ' ^ ';
    boEq: FOutput := FOutput + ' == ';
    boNotEq: FOutput := FOutput + ' != ';
    boLess: FOutput := FOutput + ' < ';
    boLessEq: FOutput := FOutput + ' <= ';
    boGreater: FOutput := FOutput + ' > ';
    boGreaterEq: FOutput := FOutput + ' >= ';
  else
    raise ENotImplemented.Create('Unknown binary operator');
  end;
  Node.ChildNode2.Accept(Self);
  FOutput := FOutput + ')';
end;

{ TKernelGeneratorBase }

constructor TKernelGeneratorBase.Create(const VectorWidth: UInt32);
begin
  inherited Create;

  FVectorWidth := VectorWidth;
end;

function TKernelGeneratorBase.GenerateDoubleTransformKernel(
  const Expression: Compute.ExprTrees.Expr): string;
var
  dataType, getIdx: string;
  logWidth: integer;
  lines: IStringList;
begin
  lines := TStringListImpl.Create;

  if (VectorWidth > 1) then
  begin
    dataType := 'double' + IntToStr(VectorWidth);
    logWidth := Round(Ln(VectorWidth) / Ln(2.0));
    getIdx := 'gid >> ' + IntToStr(logWidth);
  end
  else
  begin
    dataType := 'double';
    getIdx := 'gid';
  end;

  lines.Add('#pragma OPENCL EXTENSION cl_khr_fp64 : enable');
  lines.Add('');

  GenerateUserFunctions(Expression, lines);

  lines.Add('__kernel void transform_double(');
  lines.Add('  __global const ' + dataType + '* src,');
  lines.Add('  __global ' + dataType + '* res,');
  lines.Add('  const unsigned long num)');
  lines.Add('{');
  lines.Add('  const size_t gid = get_global_id(0);');
  lines.Add('  if (gid >= num)');
  lines.Add('    return;');
  lines.Add('  const size_t idx = ' + getIdx + ';');
  lines.Add('  const ' + dataType + ' src_value = src[idx];');

  GenerateDoubleTransformKernelBody(Expression, lines);

  lines.Add('}');

  result := StringListToStr(lines);
end;

procedure TKernelGeneratorBase.GenerateUserFunctions(
  const Expression: Compute.ExprTrees.Expr; const Lines: IStringList);
var
  visitor: IExprNodeVisitor;
  fcol: IExprFunctionCollector;
  funcs: TArray<Expr.NaryFunc>;
  bodyGen: IUserFuncBodyGenerator;
  f: Expr.NaryFunc;
  i: integer;
  s: string;
begin
  visitor := TExprFunctionCollector.Create;
  Expression.Accept(visitor);
  fcol := visitor as IExprFunctionCollector;

  funcs := fcol.Functions;

  visitor := nil;
  fcol := nil;

  bodyGen := TUserFuncBodyGenerator.Create;

  for f in funcs do
  begin
    s := 'double ' + f.Name + '(';
    for i := 1 to f.ParamCount do
    begin
      if i > 1 then
        s := s + ', ';
      s := s + 'double _' + IntToStr(i);
    end;
    s := s + ')';
    lines.Add(s);
    lines.Add('{');
    s := '  return ' + bodyGen.GenerateUserFuncBody(f.Body) + ';';
    lines.Add(s);
    lines.Add('}');
    lines.Add('');
  end;
end;

{ TGPUKernelGeneratorImpl }

constructor TGPUKernelGeneratorImpl.Create(const VectorWidth: UInt32);
begin
  inherited Create(VectorWidth);
end;

procedure TGPUKernelGeneratorImpl.GenerateDoubleTransformKernelBody(
  const Expression: Compute.ExprTrees.Expr; const Lines: IStringList);
var
  transformGenerator: IGPUTransformKernelGenerator;
  exprStr: string;
begin
  transformGenerator := TGPUTransformKernelGenerator.Create;

  exprStr := transformGenerator.TransformDouble(Expression);
  Lines.Add('  res[idx] = ' + exprStr + ';');
end;

{ TGPUTransformKernelGenerator }

constructor TGPUTransformKernelGenerator.Create;
begin
  inherited Create;
end;

function TGPUTransformKernelGenerator.TransformDouble(
  const Expression: Compute.ExprTrees.Expr): string;
begin
  FOutput := '';

  Expression.Accept(Self);

  result := FOutput;
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: IArrayElementNode);
begin
  raise ENotSupportedException.Create('Arrays not supported in transform kernel');
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: IVariableNode);
begin
  raise ENotSupportedException.Create('Variable not supported in transform kernel');
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: IConstantNode);
begin
  FOutput := FOutput + FloatToStr(Node.Data.Value, OpenCLFormatSettings);
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: IUnaryOpNode);
begin
  FOutput := FOutput + '(';
  case Node.Op of
    uoNot: FOutput := FOutput + '!';
    uoNegate: FOutput := FOutput + '-';
  else
    raise ENotImplemented.Create('Unknown unary operator');
  end;
  Node.ChildNode.Accept(Self);
  FOutput := FOutput + ')';
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: ILambdaParamNode);
begin
  FOutput := FOutput + 'src_value';
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: IFuncNode);
var
  i: integer;
begin
  FOutput := FOutput + Node.Data.Name + '(';

  for i := 0 to Node.Data.ParamCount-1 do
  begin
    if (i > 0) then
      FOutput := FOutput + ', ';

    Node.Data.Params[i].Accept(Self);
  end;

  FOutput := FOutput + ')';
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: IBinaryOpNode);
begin
  FOutput := FOutput + '(';
  Node.ChildNode1.Accept(Self);
  case Node.Op of
    boAdd: FOutput := FOutput + ' + ';
    boSub: FOutput := FOutput + ' - ';
    boMul: FOutput := FOutput + ' * ';
    boDiv: FOutput := FOutput + ' / ';
    boAnd: FOutput := FOutput + ' & ';
    boOr: FOutput := FOutput + ' | ';
    boXor: FOutput := FOutput + ' ^ ';
    boEq: FOutput := FOutput + ' == ';
    boNotEq: FOutput := FOutput + ' != ';
    boLess: FOutput := FOutput + ' < ';
    boLessEq: FOutput := FOutput + ' <= ';
    boGreater: FOutput := FOutput + ' > ';
    boGreaterEq: FOutput := FOutput + ' >= ';
  else
    raise ENotImplemented.Create('Unknown binary operator');
  end;
  Node.ChildNode2.Accept(Self);
  FOutput := FOutput + ')';
end;

initialization
  OpenCLFormatSettings := TFormatSettings.Create('en-US');
  OpenCLFormatSettings.DecimalSeparator := '.';
  OpenCLFormatSettings.ThousandSeparator := #0;

end.
