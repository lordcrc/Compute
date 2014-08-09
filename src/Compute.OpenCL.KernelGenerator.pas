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
    function GenerateDoubleTransformKernel(const Expression: Compute.ExprTrees.Expr; const NumInputs: integer = 1): string;
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
    FFunctions: IList<Expr.NaryFunc>;
    FKnownFunctions: IDictionary<string, integer>;
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

  TExpressionGeneratorBase = class(TInterfacedObject, IExprNodeVisitor)
  strict private
    FOutput: string;

  protected
    procedure Emit(const s: string);
    procedure Clear;

    procedure Visit(const Node: IConstantNode); overload; virtual;
    procedure Visit(const Node: IVariableNode); overload; virtual;
    procedure Visit(const Node: IArrayElementNode); overload; virtual;
    procedure Visit(const Node: IUnaryOpNode); overload; virtual;
    procedure Visit(const Node: IBinaryOpNode); overload; virtual;
    procedure Visit(const Node: IFuncNode); overload; virtual;
    procedure Visit(const Node: ILambdaParamNode); overload; virtual;

    property Output: string read FOutput;
  public
    constructor Create;
  end;

  IUserFuncBodyGenerator = interface
    ['{A18ECAD5-7F4B-4D47-A606-2FACBA5AF3C3}']

    function GenerateUserFuncBody(const FuncBody: Compute.ExprTrees.Expr): string;
  end;

  TUserFuncBodyGenerator = class(TExpressionGeneratorBase, IUserFuncBodyGenerator)
  strict private
    function GenerateUserFuncBody(const FuncBody: Compute.ExprTrees.Expr): string;
  protected
    procedure Visit(const Node: IVariableNode); override;
    procedure Visit(const Node: ILambdaParamNode); override;
  public
    constructor Create;
  end;

  TKernelGeneratorBase = class(TInterfacedObject, IKernelGenerator)
  strict private
    FVectorWidth: UInt32;

    procedure GenerateUserFunctions(const Expression: Compute.ExprTrees.Expr; const Lines: IStringList; const DataType: string);

    function GenerateDoubleTransformKernel(const Expression: Compute.ExprTrees.Expr; const NumInputs: integer): string;
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

  TGPUTransformKernelGenerator = class(TExpressionGeneratorBase, IGPUTransformKernelGenerator)
  strict private
    function TransformDouble(const Expression: Compute.ExprTrees.Expr): string;
  protected
    procedure Visit(const Node: IVariableNode); override;
    procedure Visit(const Node: IArrayElementNode); override;
    procedure Visit(const Node: ILambdaParamNode); override;
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

  FFunctions := TListImpl<Expr.NaryFunc>.Create;
  FKnownFunctions := TDictionaryImpl<string, integer>.Create;
end;

destructor TExprFunctionCollector.Destroy;
begin
  inherited;
end;

function TExprFunctionCollector.GetFunctions: TArray<Expr.NaryFunc>;
begin
  result := FFunctions.ToArray();
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
var
  i: integer;
begin
  if Node.Data.IsBuiltIn then
    exit;

  // make sure functions referenced
  for i := 0 to Node.Data.ParamCount-1 do
    Node.Data.Params[i].Accept(Self);

  if FKnownFunctions.Contains[Node.Data.Name] then
    exit;

  // go through body, adding any functions referenced there
  // but make sure we don't recurse
  FKnownFunctions[Node.Data.Name] := 1;

  Node.Data.Body.Accept(Self);

  // add current function after any referenced
  FFunctions.Add(Node.Data);
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

{ TExpressionGeneratorBase }

procedure TExpressionGeneratorBase.Clear;
begin
  FOutput := '';
end;

constructor TExpressionGeneratorBase.Create;
begin
  inherited Create;
end;

procedure TExpressionGeneratorBase.Emit(const s: string);
begin
  FOutput := FOutput + s;
end;

procedure TExpressionGeneratorBase.Visit(const Node: IArrayElementNode);
begin
  Emit(Node.Data.Name + '[');
  Node.Data.Index.Accept(Self);
  Emit(']');
end;

procedure TExpressionGeneratorBase.Visit(const Node: IVariableNode);
begin
  Emit(Node.Data.Name);
end;

procedure TExpressionGeneratorBase.Visit(const Node: IConstantNode);
begin
  Emit(FloatToStr(Node.Data.Value, OpenCLFormatSettings));
end;

procedure TExpressionGeneratorBase.Visit(const Node: IUnaryOpNode);
begin
  Emit('(');
  case Node.Op of
    uoNot: Emit('!');
    uoNegate: Emit('-');
  else
    raise ENotImplemented.Create('Unknown unary operator');
  end;
  Node.ChildNode.Accept(Self);
  Emit(')');
end;

procedure TExpressionGeneratorBase.Visit(const Node: ILambdaParamNode);
begin
  Emit(Node.Data.Name);
end;

procedure TExpressionGeneratorBase.Visit(const Node: IFuncNode);
var
  i: integer;
begin
  Emit(Node.Data.Name + '(');

  for i := 0 to Node.Data.ParamCount-1 do
  begin
    if (i > 0) then
      Emit(', ');

    Node.Data.Params[i].Accept(Self);
  end;

  Emit(')');
end;

procedure TExpressionGeneratorBase.Visit(const Node: IBinaryOpNode);
begin
  Emit('(');
  Node.ChildNode1.Accept(Self);
  case Node.Op of
    boAdd: Emit(' + ');
    boSub: Emit(' - ');
    boMul: Emit(' * ');
    boDiv: Emit(' / ');
    boAnd: Emit(' & ');
    boOr: Emit(' | ');
    boXor: Emit(' ^ ');
    boEq: Emit(' == ');
    boNotEq: Emit(' != ');
    boLess: Emit(' < ');
    boLessEq: Emit(' <= ');
    boGreater: Emit(' > ');
    boGreaterEq: Emit(' >= ');
  else
    raise ENotImplemented.Create('Unknown binary operator');
  end;
  Node.ChildNode2.Accept(Self);
  Emit(')');
end;

{ TUserFuncBodyGenerator }

constructor TUserFuncBodyGenerator.Create;
begin
  inherited Create;
end;

function TUserFuncBodyGenerator.GenerateUserFuncBody(
  const FuncBody: Compute.ExprTrees.Expr): string;
begin
  Clear;

  FuncBody.Accept(Self);

  result := Output;
end;

procedure TUserFuncBodyGenerator.Visit(const Node: ILambdaParamNode);
begin
  Emit('arg' + Node.Data.Name);
end;

procedure TUserFuncBodyGenerator.Visit(const Node: IVariableNode);
begin
  raise ENotImplemented.Create('Variables in functions not implemented');
end;

{ TKernelGeneratorBase }

constructor TKernelGeneratorBase.Create(const VectorWidth: UInt32);
begin
  inherited Create;

  FVectorWidth := VectorWidth;
end;

function TKernelGeneratorBase.GenerateDoubleTransformKernel(
  const Expression: Compute.ExprTrees.Expr; const NumInputs: integer): string;
var
  dataType, getIdx: string;
  logWidth: integer;
  lines: IStringList;
  i: integer;
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

  GenerateUserFunctions(Expression, lines, dataType);

  lines.Add('__kernel');
  lines.Add('__attribute__((vec_type_hint(' + dataType + ')))');
  lines.Add('void transform_double_' + IntToStr(NumInputs) +'(');
  for i := 1 to NumInputs do
    lines.Add('  __global const ' + dataType + '* src_' + IntToStr(i) + ',');
  lines.Add('  __global ' + dataType + '* res,');
  lines.Add('  const unsigned long num)');
  lines.Add('{');
  lines.Add('  const size_t gid = get_global_id(0);');
  lines.Add('  if (gid >= num)');
  lines.Add('    return;');
  lines.Add('  const size_t idx = ' + getIdx + ';');
  for i := 1 to NumInputs do
    lines.Add('  const ' + dataType + ' src_value_' + IntToStr(i) + ' = src_' + IntToStr(i) + '[idx];');

  GenerateDoubleTransformKernelBody(Expression, lines);

  lines.Add('}');

  result := StringListToStr(lines);
end;

procedure TKernelGeneratorBase.GenerateUserFunctions(
  const Expression: Compute.ExprTrees.Expr; const Lines: IStringList;
  const DataType: string);
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
    s := DataType + ' ' + f.Name + '(';
    for i := 1 to f.ParamCount do
    begin
      if i > 1 then
        s := s + ', ';
      s := s + DataType + ' arg_' + IntToStr(i);
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
  Clear;

  Expression.Accept(Self);

  result := Output;
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: ILambdaParamNode);
begin
  Emit('src_value' + Node.Data.Name);
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: IArrayElementNode);
begin
  raise ENotSupportedException.Create('Arrays not supported in transform kernel');
end;

procedure TGPUTransformKernelGenerator.Visit(const Node: IVariableNode);
begin
  raise ENotSupportedException.Create('Variable not supported in transform kernel');
end;

initialization
  OpenCLFormatSettings := TFormatSettings.Create('en-US');
  OpenCLFormatSettings.DecimalSeparator := '.';
  OpenCLFormatSettings.ThousandSeparator := #0;

end.
