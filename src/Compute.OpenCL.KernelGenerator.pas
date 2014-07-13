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

function DefaultKernelGenerator: IKernelGenerator;

implementation

uses
  System.SysUtils,
  Compute.Common;

var
  OpenCLFormatSettings: TFormatSettings;

type
  IStringList = IList<string>;
  TStringListImpl = TListImpl<string>;

  TKernelGeneratorBase = class(TInterfacedObject, IKernelGenerator)
  strict private
    function StringListToStr(const Lines: IStringList): string;

    function GenerateDoubleTransformKernel(const Expression: Compute.ExprTrees.Expr): string;
  protected
    procedure GenerateDoubleTransformKernelBody(const Expression: Compute.ExprTrees.Expr; const Lines: IStringList); virtual; abstract;
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
    constructor Create;
  end;

function DefaultKernelGenerator: IKernelGenerator;
begin
  result := TGPUKernelGeneratorImpl.Create;
end;

{ TKernelGeneratorBase }

function TKernelGeneratorBase.GenerateDoubleTransformKernel(
  const Expression: Compute.ExprTrees.Expr): string;
var
  lines: IStringList;
begin
  lines := TStringListImpl.Create;

  lines.Add('#pragma OPENCL EXTENSION cl_khr_fp64 : enable');
  lines.Add('__kernel void transform_double(');
  lines.Add('  __global const double* src,');
  lines.Add('  __global double* res,');
  lines.Add('  const unsigned long num)');
  lines.Add('{');
  lines.Add('  const size_t idx = get_global_id(0);');
  lines.Add('  if (idx >= num)');
  lines.Add('    return;');
  lines.Add('  const double src_value = src[idx];');

  GenerateDoubleTransformKernelBody(Expression, lines);

  lines.Add('}');

  result := StringListToStr(lines);
end;

function TKernelGeneratorBase.StringListToStr(const Lines: IStringList): string;
begin
  result := String.Join(#13#10, Lines.ToArray());
end;

{ TGPUKernelGeneratorImpl }

constructor TGPUKernelGeneratorImpl.Create;
begin
  inherited Create;
end;

procedure TGPUKernelGeneratorImpl.GenerateDoubleTransformKernelBody(
  const Expression: Compute.ExprTrees.Expr; const Lines: IStringList);
var
  transformGenerator: IGPUTransformKernelGenerator;
  exprStr: string;
begin
  //Lines.Add('  res[idx] = src_a[idx] + src_b[idx];');
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
  fname: string;
  i: integer;
begin
  if (Node.Data.ParamCount = 1) then
  begin
    if (Node.Data.Name = 'sign')
      or (Node.Data.Name = 'ceil')
      or (Node.Data.Name = 'floor')
      or (Node.Data.Name = 'round')
      or (Node.Data.Name = 'trunc')
      or (Node.Data.Name = 'sqrt')
      or (Node.Data.Name = 'exp')
      or (Node.Data.Name = 'exp2')
      or (Node.Data.Name = 'exp10')
      or (Node.Data.Name = 'log')
      or (Node.Data.Name = 'log2')
      or (Node.Data.Name = 'log10')
      or (Node.Data.Name = 'sin')
      or (Node.Data.Name = 'cos')
      or (Node.Data.Name = 'tan')
      or (Node.Data.Name = 'asin')
      or (Node.Data.Name = 'acos')
      or (Node.Data.Name = 'atan') then
    begin
      fname := Node.Data.Name
    end
    else if (Node.Data.Name = 'abs')
      or (Node.Data.Name = 'min')
      or (Node.Data.Name = 'max') then
    begin
      fname := 'f' + Node.Data.Name;
    end
  end
  else if (Node.Data.ParamCount = 2) then
  begin
    if (Node.Data.Name = 'pow')
      or (Node.Data.Name = 'atan2') then
    begin
      fname := Node.Data.Name;
    end;
  end;

  if (fname = '') then
    raise ENotSupportedException.Create('Functions not supported in transform kernel');

  FOutput := FOutput + fname + '(';

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
    boAnd: FOutput := FOutput + ' & ';
    boOr: FOutput := FOutput + ' | ';
    boXor: FOutput := FOutput + ' ^ ';
    boEq: FOutput := FOutput + ' == ';
    boNotEq: FOutput := FOutput + ' != ';
    boLess: FOutput := FOutput + ' < ';
    boLessEq: FOutput := FOutput + ' <= ';
    boGreater: FOutput := FOutput + ' > ';
    boGreaterEq: FOutput := FOutput + ' >= ';
  end;
  Node.ChildNode2.Accept(Self);
  FOutput := FOutput + ')';
end;

initialization
  OpenCLFormatSettings := TFormatSettings.Create('en-US');
  OpenCLFormatSettings.DecimalSeparator := '.';
  OpenCLFormatSettings.ThousandSeparator := #0;

end.
