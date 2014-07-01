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

unit Compute.Interpreter;

interface

uses
  System.SysUtils,
  System.Math,
  Generics.Collections,
  Compute.Common,
  Compute.ExprTrees,
  Compute.Statements;

type
  ESyntaxError = class(Exception);

procedure ExecProg(const p: Prog);

implementation

uses
  System.Generics.Defaults, System.DateUtils, System.RTLConsts;

type
  OpCode = (opLoad, opLoadIndirect, opStore, opStoreIndirect, opJump, opCondJump, opCall, opRet,
    opAdd, opSub, opMul, opAnd, opOr, opXor, opEq, opNotEq, opLess, opLessEq, opGreater, opGreaterEq,
    opNot, opNegate,
    // built-in functions
    opSin, opCos, opSqrt
    );

  Instruction = record
    Op: OpCode;
    Idx: integer; // mem or ip
  end;

  JumpLabel = record
    Id: integer;
    InstructionPointer: integer;
  end;

  StmtBlock = record
    StartLabelId: integer;
    EndLabelId: integer;
    class operator Equal(const s1, s2: StmtBlock): boolean;
  end;

  MemVariable = record
    Name: string;
    // index into memory slot
    // if positive index into global memory
    // if negative relative to stack pointer
    MemIdx: integer;
  end;

  MemConstant = record
    Value: double;
    MemIdx: integer;
  end;

  FuncImpl = record
    Name: string;
    ParamCount: integer;
    CallInstruction: Instruction;
  end;

  TMemory = TArray<double>;
  TBytecode = IList<Instruction>;
  TLabels = IList<JumpLabel>;
  TScopeBlockStack = IStack<StmtBlock>;

  IVariableCollector = interface
    ['{7C5B0B6A-8240-4880-B930-4B6BA1A60EA4}']
    function GetConstants: TArray<Expr.Constant>;
    function GetVariables: TArray<Expr.Variable>;
    function GetArrayVariables: TArray<Expr.ArrayVariable>;

    property Constants: TArray<Expr.Constant> read GetConstants;
    property Variables: TArray<Expr.Variable> read GetVariables;
    property ArrayVariables: TArray<Expr.ArrayVariable> read GetArrayVariables;
  end;

  TVariableCollector = class(TInterfacedObject, IVariableCollector, IStmtVisitor, IExprNodeVisitor)
  private
    type TConstantsDictionary = IDictionary<double, Expr.Constant>;
    type TVariablesDictionary = IDictionary<string, Expr.Variable>;
    type TArrayVariablesDictionary = IDictionary<string, Expr.ArrayVariable>;
  private
    FConstants: IDictionary<double, Expr.Constant>;
    FVariables: IDictionary<string, Expr.Variable>;
    FArrayVariables: IDictionary<string, Expr.ArrayVariable>;

    procedure InitializeSystemConstants;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Visit(const Stmt: IAssignStmt); overload;
    procedure Visit(const Stmt: IBeginStmt); overload;
    procedure Visit(const Stmt: IEndStmt); overload;
    procedure Visit(const Stmt: IIncStmt); overload;
    procedure Visit(const Stmt: IWhileStmt); overload;
    procedure Visit(const Stmt: IWhileDoStmt); overload;
    procedure Visit(const Stmt: IBreakStmt); overload;
    procedure Visit(const Stmt: IContinueStmt); overload;

    procedure Visit(const Node: IConstantNode); overload;
    procedure Visit(const Node: IVariableNode); overload;
    procedure Visit(const Node: IArrayElementNode); overload;
    procedure Visit(const Node: IUnaryOpNode); overload;
    procedure Visit(const Node: IBinaryOpNode); overload;
    procedure Visit(const Node: IFuncNode); overload;
    procedure Visit(const Node: ILambdaParamNode); overload;

    function GetConstants: TArray<Expr.Constant>;
    function GetVariables: TArray<Expr.Variable>;
    function GetArrayVariables: TArray<Expr.ArrayVariable>;
  end;

  IFunctionCollector = interface
    ['{1BD69C5F-A430-41AB-AD1E-0A5EF1D431EA}']
    function GetFunctions: TArray<Expr.NaryFunc>;

    property Functions: TArray<Expr.NaryFunc> read GetFunctions;
  end;

  TFunctionCollector = class(TInterfacedObject, IFunctionCollector, IStmtVisitor, IExprNodeVisitor)
  private
    FFunctions: IDictionary<string, Expr.NaryFunc>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Visit(const Stmt: IAssignStmt); overload;
    procedure Visit(const Stmt: IBeginStmt); overload;
    procedure Visit(const Stmt: IEndStmt); overload;
    procedure Visit(const Stmt: IIncStmt); overload;
    procedure Visit(const Stmt: IWhileStmt); overload;
    procedure Visit(const Stmt: IWhileDoStmt); overload;
    procedure Visit(const Stmt: IBreakStmt); overload;
    procedure Visit(const Stmt: IContinueStmt); overload;

    procedure Visit(const Node: IConstantNode); overload;
    procedure Visit(const Node: IVariableNode); overload;
    procedure Visit(const Node: IArrayElementNode); overload;
    procedure Visit(const Node: IUnaryOpNode); overload;
    procedure Visit(const Node: IBinaryOpNode); overload;
    procedure Visit(const Node: IFuncNode); overload;
    procedure Visit(const Node: ILambdaParamNode); overload;

    function GetFunctions: TArray<Expr.NaryFunc>;
  end;

  IStmtCompiler = interface
    ['{91A81D2C-BC4A-4C1D-B270-61B2253F3614}']
    function GetCompiledBytecode: TBytecode;
    function GetMemory: TMemory;
    function GetVariables: TArray<MemVariable>;
  end;

  TStmtCompiler = class(TInterfacedObject, IStmtCompiler, IStmtVisitor, IExprNodeVisitor)
  private
    FMemory: TMemory;
    FConstants: IDictionary<double, MemConstant>;
    FVariables: IDictionary<string, MemVariable>;
    FArrayVariables: IDictionary<string, MemVariable>;
    FFunctions: IDictionary<string, FuncImpl>;
    FStmtBlocks: TScopeBlockStack;
    FLoopBlocks: TScopeBlockStack;
    FLabels: IDictionary<integer, JumpLabel>;
    FBytecode: TBytecode;

    procedure InitializeMemory(const Constants: TArray<Expr.Constant>; const Variables: TArray<Expr.Variable>; const ArrayVariables: TArray<Expr.ArrayVariable>);
    procedure InitializeFunctions(const Functions: TArray<Expr.NaryFunc>);
    function AllocConst(const Value: double): MemConstant;
    function AllocVar(const Name: string): MemVariable;
    function AllocArray(const Name: string; const Count: integer): MemVariable;
    function AllocLabel: integer;
    procedure MarkLabel(const Id: integer);
    procedure Emit(const Op: OpCode; const Idx: integer = 0); overload;
    procedure Emit(const Instr: Instruction); overload;
    procedure EnterStmtBlock;
    procedure EnterLoopBlock;
    procedure ExitStmtBlock;
    procedure FixLabels;
  public
    constructor Create(
      const Constants: TArray<Expr.Constant>;
      const Variables: TArray<Expr.Variable>; const ArrayVariables: TArray<Expr.ArrayVariable>;
      const Functions: TArray<Expr.NaryFunc>);
    destructor Destroy; override;

    function GetCompiledBytecode: TBytecode;
    function GetMemory: TMemory;
    function GetVariables: TArray<MemVariable>;

    procedure Visit(const Stmt: IAssignStmt); overload;
    procedure Visit(const Stmt: IBeginStmt); overload;
    procedure Visit(const Stmt: IEndStmt); overload;
    procedure Visit(const Stmt: IIncStmt); overload;
    procedure Visit(const Stmt: IWhileStmt); overload;
    procedure Visit(const Stmt: IWhileDoStmt); overload;
    procedure Visit(const Stmt: IBreakStmt); overload;
    procedure Visit(const Stmt: IContinueStmt); overload;

    procedure Visit(const Node: IConstantNode); overload;
    procedure Visit(const Node: IVariableNode); overload;
    procedure Visit(const Node: IArrayElementNode); overload;
    procedure Visit(const Node: IUnaryOpNode); overload;
    procedure Visit(const Node: IBinaryOpNode); overload;
    procedure Visit(const Node: IFuncNode); overload;
    procedure Visit(const Node: ILambdaParamNode); overload;
  end;

  IVariableExprVisitor = interface(IExprNodeVisitor)
    function GetName: string;
    function GetIndex: double;
    function GetIsArrayElement: boolean;

    property Name: string read GetName;
    property Index: double read GetIndex;
    property IsArrayElement: boolean read GetIsArrayElement;
  end;

  TVariableExprVisitor = class(TInterfacedObject, IVariableExprVisitor)
  private
    FExprCompiler: IExprNodeVisitor;
    FName: string;
    FIndex: double;
    FIsArrayElement: boolean;
  public
    constructor Create(const ExprExec: IExprNodeVisitor);

    procedure Visit(const Node: IConstantNode); overload;
    procedure Visit(const Node: IVariableNode); overload;
    procedure Visit(const Node: IArrayElementNode); overload;
    procedure Visit(const Node: IUnaryOpNode); overload;
    procedure Visit(const Node: IBinaryOpNode); overload;
    procedure Visit(const Node: IFuncNode); overload;
    procedure Visit(const Node: ILambdaParamNode); overload;

    function GetName: string;
    function GetIndex: double;
    function GetIsArrayElement: boolean;
  end;

  IVirtualMachine = interface
    ['{CC8C8CDD-765C-4D7D-AC24-C56C65CE6E51}']
    procedure Initialize(const Memory: TMemory; const Bytecode: TBytecode);
    procedure Run;
    procedure OutputVariableValues(const Variables: TArray<MemVariable>);
  end;

  TVirtualMachineImpl = class(TInterfacedObject, IVirtualMachine)
  private
    type TOpCodeProc = procedure(const Instr: Instruction) of object;
  private
    FMemory: TMemory;
    FBytecode: TArray<Instruction>;
    FInstructionPointer: integer;
    FInstructionCount: int64;
    FStack: TMemory;
    FStackFirst: PDouble;
    FStackLast: PDouble;
    FStackPointer: PDouble;
    FBasePointer: PDouble;
    FOpCodeProcs: array[OpCode] of TOpCodeProc;
    procedure InitializeOpCodeProcs;
  protected
    procedure GrowStack;
    procedure _Push(const v: double); inline;
    function _Pop(): double; inline;
    procedure _PopN(const n: integer); inline;
    function _PopPush(const v: double): double; inline;

    procedure IncIP; inline;
    procedure SetIP(const TargetIP: integer); inline;

    procedure UnknownOp(const Instr: Instruction);
    procedure OpLoadProc(const Instr: Instruction);
    procedure OpLoadIndirectProc(const Instr: Instruction);
    procedure OpStoreProc(const Instr: Instruction);
    procedure OpStoreIndirectProc(const Instr: Instruction);
    procedure OpJumpProc(const Instr: Instruction);
    procedure OpCondJumpProc(const Instr: Instruction);
    procedure OpCallProc(const Instr: Instruction);
    procedure OpRetProc(const Instr: Instruction);
    procedure OpAddProc(const Instr: Instruction);
    procedure OpSubProc(const Instr: Instruction);
    procedure OpMulProc(const Instr: Instruction);
    procedure OpAndProc(const Instr: Instruction);
    procedure OpOrProc(const Instr: Instruction);
    procedure OpXorProc(const Instr: Instruction);
    procedure OpEqProc(const Instr: Instruction);
    procedure OpNotEqProc(const Instr: Instruction);
    procedure OpLessProc(const Instr: Instruction);
    procedure OpLessEqProc(const Instr: Instruction);
    procedure OpGreaterProc(const Instr: Instruction);
    procedure OpGreaterEqProc(const Instr: Instruction);
    procedure OpNotProc(const Instr: Instruction);
    procedure OpNegateProc(const Instr: Instruction);
    procedure OpSinProc(const Instr: Instruction);
    procedure OpCosProc(const Instr: Instruction);
    procedure OpSqrtProc(const Instr: Instruction);
  public
    constructor Create;
    procedure Initialize(const Memory: TMemory; const Bytecode: TBytecode);
    procedure Run;
    procedure OutputVariableValues(const Variables: TArray<MemVariable>);
  end;

procedure PrintBytecode(const bytecode: TBytecode; const Variables: TArray<MemVariable>);

  function VarName(const MemIdx: integer): string;
  var
    i: integer;
  begin
    for i := 0 to High(Variables) do
      if (Variables[i].MemIdx = MemIdx) then
      begin
        result := Variables[i].Name;
        exit;
      end;
    result := IntToStr(MemIdx);
  end;

const
  OpName: array[OpCode] of string = (
    'load', 'loadind', 'store', 'storeind', 'jump', 'condjump', 'call', 'ret',
    'add', 'sub', 'mul', 'and', 'or', 'xor', 'eq', 'noteq', 'less', 'lesseq', 'greater', 'greatereq',
    'not', 'negate',
    'sin', 'cos', 'sqrt');
var
  i: integer;
  instr: Instruction;
begin
  for i := 0 to bytecode.Count-1 do
  begin
    instr := bytecode[i];
    if (instr.Op in [opLoad, opLoadIndirect, opStore, opStoreIndirect]) then
      WriteLn(Format('%.6d: %9s  [%s]', [i, OpName[instr.Op], VarName(instr.Idx)]))
    else if (instr.Op in [opJump, opCondJump]) then
      WriteLn(Format('%.6d: %9s  %d', [i, OpName[instr.Op], instr.Idx]))
    else
      WriteLn(Format('%.6d: %9s', [i, OpName[instr.Op]]));
  end;
end;

procedure ExecProg(const p: Prog);
var
  visitor: IStmtVisitor;
  vcol: IVariableCollector;
  fcol: IFunctionCollector;
  comp: IStmtCompiler;
  bytecode: TBytecode;
  mem: TMemory;
  vars: TArray<MemVariable>;
  vm: IVirtualMachine;
begin
  WriteLn('Code:');
  PrintProg(p);
  WriteLn;

  // codegen error when using "as" the other way around for visitor/vcol
  visitor := TVariableCollector.Create;
  p.Accept(visitor);
  vcol := visitor as IVariableCollector;

  visitor := TFunctionCollector.Create;
  p.Accept(visitor);
  fcol := visitor as IFunctionCollector;

  visitor := TStmtCompiler.Create(vcol.Constants, vcol.Variables, vcol.ArrayVariables, fcol.Functions);
  vcol := nil;
  fcol := nil;
  p.Accept(visitor);
  comp := visitor as IStmtCompiler;

  mem := comp.GetMemory;
  bytecode := comp.GetCompiledBytecode;

  vars := comp.GetVariables;
  WriteLn('Bytecode:');
  PrintBytecode(bytecode, vars);
  WriteLn;

  vm := TVirtualMachineImpl.Create;
  vm.Initialize(mem, bytecode);

  vm.Run;

  WriteLn('Variables:');
  vm.OutputVariableValues(vars);
end;

procedure RaiseSyntaxErrorException;
begin
  raise ESyntaxError.Create('Syntax Error');
end;

procedure RaiseInvalidOp(const msg: string = '');
begin
  raise EInvalidOpException.Create(msg);
end;

function GetConstantName(const v: double): string;
begin
  result := '%' + IntToHex(PUInt64(@v)^, 8);
end;

{ StmtBlock }

class operator StmtBlock.Equal(const s1, s2: StmtBlock): boolean;
begin
  result := (s1.StartLabelId = s2.StartLabelId) and (s1.EndLabelId = s2.EndLabelId);
end;

{ TVariableCollector }

constructor TVariableCollector.Create;
begin
  inherited Create;

  FConstants := TDictionaryImpl<double, Expr.Constant>.Create;
  FVariables := TDictionaryImpl<string, Expr.Variable>.Create;
  FArrayVariables := TDictionaryImpl<string, Expr.ArrayVariable>.Create;

  InitializeSystemConstants;
end;

destructor TVariableCollector.Destroy;
begin
  inherited;
end;

function TVariableCollector.GetArrayVariables: TArray<Expr.ArrayVariable>;
begin
  result := FArrayVariables.Values;
end;

function TVariableCollector.GetConstants: TArray<Expr.Constant>;
begin
  result := FConstants.Values;
end;

function TVariableCollector.GetVariables: TArray<Expr.Variable>;
begin
  result := FVariables.Values;
end;

procedure TVariableCollector.InitializeSystemConstants;
var
  c: Expr.Constant;
begin
  c := Constant(1.0);
  FConstants[c.Value] := c;
end;

procedure TVariableCollector.Visit(const Node: IBinaryOpNode);
begin
  Node.ChildNode1.Accept(Self);
  Node.ChildNode2.Accept(Self);
end;

procedure TVariableCollector.Visit(const Node: IFuncNode);
var
  i: integer;
begin
  for i := 0 to Node.Data.ParamCount-1 do
    Node.Data.Params[i].Accept(Self);
  Node.Data.Body.Accept(Self);
end;

procedure TVariableCollector.Visit(const Node: IUnaryOpNode);
begin
  Node.ChildNode.Accept(Self);
end;

procedure TVariableCollector.Visit(const Node: IConstantNode);
begin
  FConstants[Node.Data.Value] := Node.Data;
end;

procedure TVariableCollector.Visit(const Node: IVariableNode);
begin
  FVariables[Node.Data.Name] := Node.Data;
end;

procedure TVariableCollector.Visit(const Node: IArrayElementNode);
var
  av: Expr.ArrayVariable;
begin
  av := ArrayVariable(Node.Data.Name, Node.Data.Count);
  FArrayVariables[Node.Data.Name] := av;
end;

procedure TVariableCollector.Visit(const Stmt: IAssignStmt);
begin
  Stmt.Variable.Accept(Self);
  Stmt.Value.Accept(Self);
end;

procedure TVariableCollector.Visit(const Stmt: IWhileDoStmt);
begin
  // no-op
end;

procedure TVariableCollector.Visit(const Stmt: IBreakStmt);
begin
  // no-op
end;

procedure TVariableCollector.Visit(const Stmt: IContinueStmt);
begin
  // no-op
end;

procedure TVariableCollector.Visit(const Stmt: IWhileStmt);
begin
  Stmt.WhileCondExpr.Accept(Self);
end;

procedure TVariableCollector.Visit(const Stmt: IBeginStmt);
begin
  // no-op
end;

procedure TVariableCollector.Visit(const Stmt: IEndStmt);
begin
  // no-op
end;

procedure TVariableCollector.Visit(const Stmt: IIncStmt);
begin
  Stmt.Variable.Accept(Self);
  Stmt.Value.Accept(Self);
end;

procedure TVariableCollector.Visit(const Node: ILambdaParamNode);
begin

end;

{ TFunctionCollector }

constructor TFunctionCollector.Create;
begin
  inherited Create;

  FFunctions := TDictionaryImpl<string, Expr.NaryFunc>.Create;
end;

destructor TFunctionCollector.Destroy;
begin
  inherited;
end;

function TFunctionCollector.GetFunctions: TArray<Expr.NaryFunc>;
begin
  result := FFunctions.Values;
end;

procedure TFunctionCollector.Visit(const Stmt: IIncStmt);
begin
  Stmt.Value.Accept(Self);
end;

procedure TFunctionCollector.Visit(const Stmt: IWhileStmt);
begin
  Stmt.WhileCondExpr.Accept(Self);
end;

procedure TFunctionCollector.Visit(const Stmt: IWhileDoStmt);
begin

end;

procedure TFunctionCollector.Visit(const Stmt: IAssignStmt);
begin
  Stmt.Value.Accept(Self);
end;

procedure TFunctionCollector.Visit(const Stmt: IBeginStmt);
begin

end;

procedure TFunctionCollector.Visit(const Stmt: IEndStmt);
begin

end;

procedure TFunctionCollector.Visit(const Stmt: IBreakStmt);
begin

end;

procedure TFunctionCollector.Visit(const Node: IUnaryOpNode);
begin
  Node.ChildNode.Accept(Self);
end;

procedure TFunctionCollector.Visit(const Node: IBinaryOpNode);
begin
  Node.ChildNode1.Accept(Self);
  Node.ChildNode2.Accept(Self);
end;

procedure TFunctionCollector.Visit(const Node: IFuncNode);
begin
  FFunctions[Node.Data.Name] := Node.Data;
end;

procedure TFunctionCollector.Visit(const Node: IArrayElementNode);
begin
  Node.Data.Index.Accept(Self);
end;

procedure TFunctionCollector.Visit(const Stmt: IContinueStmt);
begin

end;

procedure TFunctionCollector.Visit(const Node: IConstantNode);
begin

end;

procedure TFunctionCollector.Visit(const Node: IVariableNode);
begin

end;

procedure TFunctionCollector.Visit(const Node: ILambdaParamNode);
begin

end;

{ TStmtCompiler }

function TStmtCompiler.AllocArray(const Name: string; const Count: integer): MemVariable;
var
  i: integer;
begin
  i := Length(FMemory);
  SetLength(FMemory, i + Count);
  result.Name := Name;
  result.MemIdx := i;
end;

function TStmtCompiler.AllocConst(const Value: double): MemConstant;
var
  i: integer;
begin
  i := Length(FMemory);
  SetLength(FMemory, i + 1);
  FMemory[i] := Value;
  result.Value := Value;
  result.MemIdx := i;
end;

function TStmtCompiler.AllocLabel: integer;
var
  lb: JumpLabel;
begin
  lb.Id := -1 * (FLabels.Count + 1); // labels have negative id to separate them more easily from mem index and actual ip's
  lb.InstructionPointer := -1;
  FLabels[lb.Id] := lb;
  result := lb.Id;
end;

function TStmtCompiler.AllocVar(const Name: string): MemVariable;
var
  i: integer;
begin
  i := Length(FMemory);
  SetLength(FMemory, i + 1);
  result.Name := Name;
  result.MemIdx := i;
end;

constructor TStmtCompiler.Create(const Constants: TArray<Expr.Constant>;
  const Variables: TArray<Expr.Variable>; const ArrayVariables: TArray<Expr.ArrayVariable>;
  const Functions: TArray<Expr.NaryFunc>);
var
  entryPoint: integer;
begin
  inherited Create;

  FConstants := TDictionaryImpl<double, MemConstant>.Create;
  FVariables := TDictionaryImpl<string, MemVariable>.Create;
  FArrayVariables := TDictionaryImpl<string, MemVariable>.Create;
  FFunctions := TDictionaryImpl<string, FuncImpl>.Create;
  FLabels := TDictionaryImpl<integer, JumpLabel>.Create;

  FStmtBlocks := TStackImpl<StmtBlock>.Create;
  FLoopBlocks := TStackImpl<StmtBlock>.Create;
  FBytecode := TListImpl<Instruction>.Create;

  // jump over function bodies
  entryPoint := AllocLabel;
  Emit(opJump, entryPoint);

  InitializeMemory(Constants, Variables, ArrayVariables);
  // emits function bodies
  InitializeFunctions(Functions);
  // program comes after functions
  MarkLabel(entryPoint);
end;

destructor TStmtCompiler.Destroy;
begin
  inherited;
end;

procedure TStmtCompiler.Emit(const Op: OpCode; const Idx: integer);
var
  instr: Instruction;
begin
  instr.Op := Op;
  instr.Idx := Idx;
  Emit(Instr);
end;

procedure TStmtCompiler.Emit(const Instr: Instruction);
begin
  FBytecode.Add(Instr);
end;

procedure TStmtCompiler.EnterLoopBlock;
begin
  EnterStmtBlock;
  FLoopBlocks.Push(FStmtBlocks.Top);
end;

procedure TStmtCompiler.EnterStmtBlock;
var
  block: StmtBlock;
begin
  block.StartLabelId := AllocLabel;
  block.EndLabelId := AllocLabel;
  FStmtBlocks.Push(block);
  MarkLabel(block.StartLabelId);
end;

procedure TStmtCompiler.ExitStmtBlock;
var
  block: StmtBlock;
begin
  block := FStmtBlocks.Pop;
  if (block = FLoopBlocks.Top) then
  begin
    FLoopBlocks.Pop;
    Emit(opJump, block.StartLabelId);
  end;
  MarkLabel(block.EndLabelId);
end;

procedure TStmtCompiler.FixLabels;
var
  i: integer;
  instr: Instruction;
begin
  for i := 0 to FBytecode.Count-1 do
  begin
    instr := FBytecode[i];

    if not (instr.Op in [opJump, opCondJump, opCall]) then
      continue;

    instr.Idx := FLabels[instr.Idx].InstructionPointer;
    FBytecode[i] := instr;
  end;
end;

function TStmtCompiler.GetCompiledBytecode: TBytecode;
begin
  FixLabels;
  result := FBytecode;
end;

function TStmtCompiler.GetMemory: TMemory;
begin
  result := FMemory;
end;

function TStmtCompiler.GetVariables: TArray<MemVariable>;
begin
  result := FVariables.Values;
end;

procedure TStmtCompiler.InitializeFunctions(
  const Functions: TArray<Expr.NaryFunc>);

  procedure AddBuiltInFunc(const Name: string; const ParamCount: integer; const Op: OpCode);
  var
    fimpl: FuncImpl;
  begin
    fimpl.Name := Name;
    fimpl.ParamCount := ParamCount;
    fimpl.CallInstruction.Op := Op;
    fimpl.CallInstruction.Idx := 0;
    FFunctions[Name] := fimpl;
  end;

  procedure AddStackVar(const VarIdx: integer);
  var
    mv: MemVariable;
  begin
    mv.Name := '_' + IntToStr(VarIdx);
    mv.MemIdx := -VarIdx; // stack variables have negative memory index
    FVariables[mv.Name] := mv;
  end;

var
  f: Expr.NaryFunc;
  fimpl: FuncImpl;
  fbodyLabelId: integer;
  i, maxLambdaParams: integer;
begin
  AddBuiltInFunc('sin', 1, opSin);
  AddBuiltInFunc('cos', 1, opCos);
  AddBuiltInFunc('sqrt', 1, opSqrt);

  maxLambdaParams := 0;

  for f in Functions do
  begin
    // add lambda parameters to known variables
    if (f.ParamCount > maxLambdaParams) then
    begin
      for i := maxLambdaParams+1 to f.ParamCount do
        AddStackVar(i);
      maxLambdaParams := f.ParamCount;
    end;

    // skip built-in functions
    if FFunctions.Contains[f.Name] then
    begin
      fimpl := FFunctions[f.Name];

      if (fimpl.ParamCount <> f.ParamCount) then
        raise Exception.CreateFmt('Invalid number of function parameters: %s', [f.Name]);

      continue;
    end;

    fbodyLabelId := AllocLabel;

    fimpl.Name := f.Name;
    fimpl.ParamCount := f.ParamCount;
    fimpl.CallInstruction.Op := opCall;
    fimpl.CallInstruction.Idx := fbodyLabelId;

    FFunctions[fimpl.Name] := fimpl;

    // emit function body
    MarkLabel(fbodyLabelId);
    f.Body.Accept(Self);
    Emit(opRet, fimpl.ParamCount);
  end;
end;

procedure TStmtCompiler.InitializeMemory(const Constants: TArray<Expr.Constant>;
  const Variables: TArray<Expr.Variable>; const ArrayVariables: TArray<Expr.ArrayVariable>);
var
  c: Expr.Constant;
  mc: MemConstant;
  v: Expr.Variable;
  mv: MemVariable;
  av: Expr.ArrayVariable;
begin
  for c in Constants do
  begin
    mc := AllocConst(c.Value);
    FConstants[mc.Value] := mc;
  end;
  for v in Variables do
  begin
    mv := AllocVar(v.Name);
    FVariables[mv.Name] := mv;
  end;
  for av in ArrayVariables do
  begin
    mv := AllocArray(av.Name, av.Count);
    FArrayVariables[mv.Name] := mv;
  end;
end;

procedure TStmtCompiler.MarkLabel(const Id: integer);
var
  lb: JumpLabel;
begin
  lb := FLabels[Id];
  lb.InstructionPointer := FBytecode.Count;
  FLabels[Id] := lb;
end;

procedure TStmtCompiler.Visit(const Node: IArrayElementNode);
begin
  Node.Data.Index.Accept(Self);
  Emit(opLoadIndirect, FVariables[Node.Data.Name].MemIdx);
end;

procedure TStmtCompiler.Visit(const Node: IVariableNode);
begin
  Emit(opLoad, FVariables[Node.Data.Name].MemIdx);
end;

procedure TStmtCompiler.Visit(const Node: IConstantNode);
begin
  Emit(opLoad, FConstants[Node.Data.Value].MemIdx);
end;

procedure TStmtCompiler.Visit(const Node: IFuncNode);
var
  i: integer;
  fimpl: FuncImpl;
begin
  // push parameters on stack, reverse order so first parameter is on top
  for i := Node.Data.ParamCount-1 downto 0 do
    Node.Data.Params[i].Accept(Self);
  // call function
  if not FFunctions.Contains[Node.Data.Name] then
    raise Exception.Create('internal error, function not found when compiling bytecode');
  fimpl := FFunctions[Node.Data.Name];
  Emit(fimpl.CallInstruction);
end;

procedure TStmtCompiler.Visit(const Node: IBinaryOpNode);
const
  OpMap: array[BinaryOpType] of OpCode =
    (opAdd, opSub, opMul, opAnd, opOr, opXor, opEq, opNotEq, opLess, opLessEq, opGreater, opGreaterEq);
var
  op: OpCode;
begin
  Node.ChildNode1.Accept(Self);
  Node.ChildNode2.Accept(Self);

  op := OpMap[Node.Op];
  Emit(op);
end;

procedure TStmtCompiler.Visit(const Node: IUnaryOpNode);
const
  OpMap: array[UnaryOpType] of OpCode =
    (opNot, opNegate);
var
  op: OpCode;
begin
  Node.ChildNode.Accept(Self);

  op := OpMap[Node.Op];
  Emit(op);
end;

procedure TStmtCompiler.Visit(const Stmt: IEndStmt);
begin
  // single-line if/while/for etc statements
  // are automatically wrapped in begin/end
  // this also exits the loop block if applicable
  ExitStmtBlock;
end;

procedure TStmtCompiler.Visit(const Stmt: IIncStmt);
var
  target: IVariableExprVisitor;
begin
  Stmt.Variable.Accept(Self);
  Stmt.Value.Accept(Self);

  Emit(opAdd);

  target := TVariableExprVisitor.Create(Self);
  Stmt.Variable.Accept(target);

  if (target.IsArrayElement) then
  begin
    Emit(opStoreIndirect, FVariables[target.Name].MemIdx);
  end
  else
  begin
    Emit(opStore, FVariables[target.Name].MemIdx);
  end;
end;

procedure TStmtCompiler.Visit(const Stmt: IAssignStmt);
var
  target: IVariableExprVisitor;
begin
  Stmt.Value.Accept(Self);

  target := TVariableExprVisitor.Create(Self);
  Stmt.Variable.Accept(target);

  if (target.IsArrayElement) then
  begin
    Emit(opStoreIndirect, FVariables[target.Name].MemIdx);
  end
  else
  begin
    Emit(opStore, FVariables[target.Name].MemIdx);
  end;
end;

procedure TStmtCompiler.Visit(const Stmt: IBeginStmt);
begin

end;

procedure TStmtCompiler.Visit(const Stmt: IBreakStmt);
begin
  Emit(opJump, FLoopBlocks.Top.EndLabelId);
end;

procedure TStmtCompiler.Visit(const Stmt: IContinueStmt);
begin
  Emit(opJump, FLoopBlocks.Top.StartLabelId);
end;

procedure TStmtCompiler.Visit(const Stmt: IWhileStmt);
var
  labelIdBody: Integer;
begin
  EnterLoopBlock;

  labelIdBody := AllocLabel;

  Stmt.WhileCondExpr.Accept(Self);
  Emit(opCondJump, labelIdBody);
  Emit(opJump, FStmtBlocks.Top.EndLabelId);
  MarkLabel(labelIdBody);
end;

procedure TStmtCompiler.Visit(const Stmt: IWhileDoStmt);
begin

end;

procedure TStmtCompiler.Visit(const Node: ILambdaParamNode);
begin
  // lambda params are stored as regular vars but with negative MemIdx
  Emit(opLoad, FVariables[Node.Data.Name].MemIdx);
end;

{ TVariableExprVisitor }

constructor TVariableExprVisitor.Create(const ExprExec: IExprNodeVisitor);
begin
  inherited Create;

  FExprCompiler := ExprExec;
end;

function TVariableExprVisitor.GetIndex: double;
begin
  result := FIndex;
end;

function TVariableExprVisitor.GetIsArrayElement: boolean;
begin
  result := FIsArrayElement;
end;

function TVariableExprVisitor.GetName: string;
begin
  result := FName;
end;

procedure TVariableExprVisitor.Visit(const Node: ILambdaParamNode);
begin
  RaiseSyntaxErrorException;
end;

procedure TVariableExprVisitor.Visit(const Node: IVariableNode);
begin
  FName := Node.Data.Name;
end;

procedure TVariableExprVisitor.Visit(const Node: IConstantNode);
begin
  RaiseSyntaxErrorException;
end;

procedure TVariableExprVisitor.Visit(const Node: IBinaryOpNode);
begin
  RaiseSyntaxErrorException;
end;

procedure TVariableExprVisitor.Visit(const Node: IFuncNode);
begin
  RaiseSyntaxErrorException;
end;

procedure TVariableExprVisitor.Visit(const Node: IArrayElementNode);
begin
  FIsArrayElement := True;
  FName := Node.Data.Name;
  Node.Data.Index.Accept(FExprCompiler);
end;

procedure TVariableExprVisitor.Visit(const Node: IUnaryOpNode);
begin
  RaiseSyntaxErrorException;
end;

{ TVirtualMachineImpl }

function TVirtualMachineImpl._Pop: double;
begin
  result := FStackPointer^;
{$IFDEF DEBUG}
  FStackPointer^ := 0;
{$ENDIF}
  Dec(FStackPointer);
  if NativeUInt(FStackPointer) < NativeUInt(FStackFirst) then
    RaiseInvalidOp('stack underflow');
end;

procedure TVirtualMachineImpl._PopN(const n: integer);
{$IFDEF DEBUG}
var
  i: integer;
begin
  for i := 0 to n-1 do
    _Pop;
end;
{$ELSE}
begin
  Dec(FStackPointer, n);
  if NativeUInt(FStackPointer) < NativeUInt(FStackFirst) then
    RaiseInvalidOp('stack underflow');
end;
{$ENDIF}

function TVirtualMachineImpl._PopPush(const v: double): double;
begin
  // Pop followed by Push
  result := FStackPointer^;
  FStackPointer^ := v;
end;

procedure TVirtualMachineImpl._Push(const v: double);
begin
  Inc(FStackPointer);
  if NativeUInt(FStackPointer) > NativeUInt(FStackLast) then
    GrowStack;
  FStackPointer^ := v;
end;

constructor TVirtualMachineImpl.Create;
begin
  inherited Create;

  InitializeOpCodeProcs;
end;

procedure TVirtualMachineImpl.GrowStack;
var
  spi, bpi: integer;
begin
  spi := NativeUInt(FStackPointer) - NativeUInt(FStackFirst);
  SetLength(FStack, System.Math.Max(16, Length(FStack)*2));
  FStackFirst := @FStack[0];
  FStackLast := @FStack[Length(FStack)-1];
  FStackPointer := FStackFirst;
  Inc(spi, NativeUInt(FStackPointer));
  FStackPointer := PDouble(spi);
  FBasePointer := FStackFirst;
  Inc(bpi, NativeUInt(FBasePointer));
  FBasePointer := PDouble(bpi);
end;

procedure TVirtualMachineImpl.IncIP;
begin
  FInstructionPointer := FInstructionPointer + 1;
end;

procedure TVirtualMachineImpl.Initialize(const Memory: TMemory; const Bytecode: TBytecode);
begin
  FMemory := Memory;
  FBytecode := Bytecode.ToArray();
  FInstructionPointer := 0;
  FInstructionCount := 0;
  FStack := nil;
  FStackFirst := nil;
  FStackPointer := nil;
  FBasePointer := nil;
  FStackLast := nil;
end;

procedure TVirtualMachineImpl.InitializeOpCodeProcs;
var
  op: OpCode;
begin
  for op := Low(OpCode) to High(OpCode) do
    FOpCodeProcs[op] := UnknownOp;

  FOpCodeProcs[opLoad] := OpLoadProc;
  FOpCodeProcs[opLoadIndirect] := OpLoadIndirectProc;
  FOpCodeProcs[opStore] := OpStoreProc;
  FOpCodeProcs[opStoreIndirect] := OpStoreIndirectProc;
  FOpCodeProcs[opJump] := OpJumpProc;
  FOpCodeProcs[opCondJump] := OpCondJumpProc;
  FOpCodeProcs[opCall] := OpCallProc;
  FOpCodeProcs[opRet] := OpRetProc;
  FOpCodeProcs[opAdd] := OpAddProc;
  FOpCodeProcs[opSub] := OpSubProc;
  FOpCodeProcs[opMul] := OpMulProc;
  FOpCodeProcs[opAnd] := OpAndProc;
  FOpCodeProcs[opOr] := OpOrProc;
  FOpCodeProcs[opXor] := OpXorProc;
  FOpCodeProcs[opEq] := OpEqProc;
  FOpCodeProcs[opNotEq] := OpNotEqProc;
  FOpCodeProcs[opLess] := OpLessProc;
  FOpCodeProcs[opLessEq] := OpLessEqProc;
  FOpCodeProcs[opGreater] := OpGreaterProc;
  FOpCodeProcs[opGreaterEq] := OpGreaterEqProc;
  FOpCodeProcs[opNot] := OpNotProc;
  FOpCodeProcs[opNegate] := OpNegateProc;
  FOpCodeProcs[opSin] := OpSinProc;
  FOpCodeProcs[opCos] := OpCosProc;
  FOpCodeProcs[opSqrt] := OpSqrtProc;
end;

procedure TVirtualMachineImpl.OpAddProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := v1 + v2;
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpAndProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := Ord((v1 <> 0) and (v2 <> 0));
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpCallProc(const Instr: Instruction);
var
  bp: integer;
begin
  bp := NativeUInt(FBasePointer) - NativeUInt(FStackFirst);
  _Push(bp);
  // update base pointer
  FBasePointer := FStackPointer;
  _Push(FInstructionPointer+1);
  SetIP(Instr.Idx);
end;

procedure TVirtualMachineImpl.OpCondJumpProc(const Instr: Instruction);
var
  cond: double;
begin
  cond := _Pop;
  if (cond <> 0) then
    SetIP(Instr.Idx)
  else
    IncIP;
end;

procedure TVirtualMachineImpl.OpCosProc(const Instr: Instruction);
var
  v, r: double;
begin
  v := _Pop;
  r := Cos(v);
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpEqProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := Ord(v1 = v2);
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpGreaterEqProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := Ord(v1 >= v2);
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpGreaterProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := Ord(v1 > v2);
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpJumpProc(const Instr: Instruction);
begin
  SetIP(Instr.Idx);
end;

procedure TVirtualMachineImpl.OpLessEqProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := Ord(v1 <= v2);
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpLessProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := Ord(v1 < v2);
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpLoadIndirectProc(const Instr: Instruction);
var
  ofs, v: double;
  midx: integer;
begin
  if (Instr.Idx < 0) then
    raise ENotImplemented.Create('stack array variables');

  // this should be ok, as a double should have at least 52 integer bits
  ofs := _Pop;
  midx := Instr.Idx + Round(ofs);
  v := FMemory[midx];
  _Push(v);
  IncIP;
end;

procedure TVirtualMachineImpl.OpLoadProc(const Instr: Instruction);
var
  v: double;
  sp: PDouble;
begin
  if (Instr.Idx < 0) then
  begin
    // load from stack
    sp := FBasePointer;
    Inc(sp, Instr.Idx);
    v := sp^;
  end
  else
    v := FMemory[Instr.Idx];
  _Push(v);
  IncIP;
end;

procedure TVirtualMachineImpl.OpMulProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := v1 * v2;
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpNegateProc(const Instr: Instruction);
var
  v, r: double;
begin
  v := _Pop;
  r := -v;
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpNotEqProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := Ord(v1 <> v2);
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpNotProc(const Instr: Instruction);
var
  v, r: double;
begin
  v := _Pop;
  r := Ord(not (v <> 0));
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpOrProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := Ord((v1 <> 0) or (v2 <> 0));
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpRetProc(const Instr: Instruction);
var
  rv, ripv, bpv: double;
  rip, bp: integer;
begin
  // save return value
  rv := _Pop;

  // get return IP
  ripv := _Pop;
  bpv := _Pop;
  rip := Round(ripv);
  bp := Round(bpv);

  // remove function parameters from stack
  if (Instr.Idx > 0) then
    _PopN(Instr.Idx);

  // restore base pointer
  FBasePointer := FStackFirst;
  Inc(FBasePointer, bp);

  // place return value back on stack
  _Push(rv);

  // and jump
  SetIP(rip);
end;

procedure TVirtualMachineImpl.OpSinProc(const Instr: Instruction);
var
  v, r: double;
begin
  v := _Pop;
  r := Sin(v);
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpSqrtProc(const Instr: Instruction);
var
  v, r: double;
begin
  v := _Pop;
  r := Sqrt(v);
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpStoreIndirectProc(const Instr: Instruction);
var
  ofs, v: double;
  midx: integer;
begin
  // this should be ok, as a double should have at least 52 integer bits
  ofs := _Pop;
  midx := Instr.Idx + Round(ofs);
  v := _Pop;
  FMemory[midx] := v;
  IncIP;
end;

procedure TVirtualMachineImpl.OpStoreProc(const Instr: Instruction);
var
  v: double;
begin
  v := _Pop;
  FMemory[Instr.Idx] := v;
  IncIP;
end;

procedure TVirtualMachineImpl.OpSubProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := v1 * v2;
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OpXorProc(const Instr: Instruction);
var
  v1, v2, r: double;
begin
  v2 := _Pop;
  v1 := _Pop;
  r := Ord((v1 <> 0) xor (v2 <> 0));
  _Push(r);
  IncIP;
end;

procedure TVirtualMachineImpl.OutputVariableValues(const Variables: TArray<MemVariable>);
var
  vars: TArray<MemVariable>;
  mv: MemVariable;
begin
  vars := Variables;
  TArray.Sort<MemVariable>(vars, TDelegatedComparer<MemVariable>.Create(
    function(const Left, Right: MemVariable): integer
    begin
      result := CompareStr(Left.Name, Right.Name);
    end
  ));
  for mv in vars do
  begin
    // skip stack variables
    if (mv.MemIdx < 0) then
      continue;

    WriteLn(Format('%.3d: %s = %.6g', [mv.MemIdx, mv.Name, FMemory[mv.MemIdx]]));
  end;
end;

procedure TVirtualMachineImpl.Run;
var
  instr: Instruction;
  st, ft: TTime;
  msec: int64;
begin
  st := GetTime;
  while FInstructionPointer < Length(FBytecode) do
  begin
    FInstructionCount := FInstructionCount + 1;
    //Write(Format(#13'%d     ', [FInstructionPointer]));
    instr := FBytecode[FInstructionPointer];
    FOpCodeProcs[instr.Op](instr);
  end;
  ft := GetTime;
  msec := MilliSecondsBetween(ft, st);
  WriteLn(Format(#13'Program done, %d instructions executed in %dmsec (%.2f Mips/sec).                   ', [FInstructionCount, msec, (1e-3 * FInstructionCount / msec)]));
  WriteLn;
end;

procedure TVirtualMachineImpl.SetIP(const TargetIP: integer);
begin
  FInstructionPointer := TargetIP;
end;

procedure TVirtualMachineImpl.UnknownOp(const Instr: Instruction);
begin
  raise ENotImplemented.Create('unknown op');
end;


end.
