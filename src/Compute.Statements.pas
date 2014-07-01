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

unit Compute.Statements;

interface

uses
  Generics.Collections,
  Compute.Common,
  Compute.ExprTrees;

type
  IStmtVisitor = interface;
  IStmtTransformer = interface;

  IStmt = interface
    ['{1220E127-F6B9-44AF-8F60-267C56E20F76}']
    procedure Accept(const Visitor: IStmtVisitor); overload;
    function Accept(const Transformer: IStmtTransformer): IStmt; overload;
  end;

  IAssignStmt = interface;
  IBeginStmt = interface;
  IEndStmt = interface;
  IIncStmt = interface;
  IWhileStmt = interface;
  IWhileDoStmt = interface;
  IBreakStmt = interface;
  IContinueStmt = interface;

  IStmtVisitor = interface
    ['{BACAD5B1-B34A-4DA6-B87F-F7BE8D853F93}']
    procedure Visit(const Stmt: IAssignStmt); overload;
    procedure Visit(const Stmt: IBeginStmt); overload;
    procedure Visit(const Stmt: IEndStmt); overload;
    procedure Visit(const Stmt: IIncStmt); overload;
    procedure Visit(const Stmt: IWhileStmt); overload;
    procedure Visit(const Stmt: IWhileDoStmt); overload;
    procedure Visit(const Stmt: IBreakStmt); overload;
    procedure Visit(const Stmt: IContinueStmt); overload;
  end;

  IStmtTransformer = interface
    ['{96D4249B-D6D3-45FB-B867-384220EA82D9}']
      function Transform(const Stmt: IAssignStmt): IAssignStmt; overload;
      function Transform(const Stmt: IBeginStmt): IBeginStmt; overload;
      function Transform(const Stmt: IEndStmt): IEndStmt; overload;
      function Transform(const Stmt: IIncStmt): IIncStmt; overload;
      function Transform(const Stmt: IWhileStmt): IWhileStmt; overload;
      function Transform(const Stmt: IWhileDoStmt): IWhileDoStmt; overload;
      function Transform(const Stmt: IBreakStmt): IBreakStmt; overload;
      function Transform(const Stmt: IContinueStmt): IContinueStmt; overload;
  end;

  StmtList = IList<IStmt>;

  Prog = record
  strict private
    FStmtList: StmtList;
  public
    type
      Stmt1 = record
      private
        FStmtList: StmtList;
      end;
      WhileStmt1 = record
      private
        FStmtList: StmtList;
      end;
      LoopStmt1 = record
      private
        FStmtList: StmtList;
      end;
      LoopBlockStmt1 = record
      private
        FStmtList: StmtList;
      end;

      NestedStmt2 = record
      private
        FStmtList: StmtList;
      end;
      NestedWhileStmt2 = record
      private
        FStmtList: StmtList;
      end;
      NestedLoopStmt2 = record
      private
        FStmtList: StmtList;
      end;
      NestedLoopBlockStmt2 = record
      private
        FStmtList: StmtList;
      end;

      StmtImpl1 = record helper for Stmt1
      public
        function assign_(const VarExpr, ValExpr: Expr): Stmt1;
        function inc_(const VarExpr: Expr): Stmt1; overload;
        function inc_(const VarExpr, ValExpr: Expr): Stmt1; overload;
        function while_(const WhileCondExpr: Expr): Prog.WhileStmt1;
      end;
      WhileStmtImpl1 = record helper for WhileStmt1
      public
        function do_(): LoopStmt1;
      end;
      LoopStmtImpl1 = record helper for LoopStmt1
      public
        function assign_(const VarExpr, ValExpr: Expr): Stmt1;
        function begin_(): LoopBlockStmt1;
      end;
      LoopBlockStmtImpl1 = record helper for LoopBlockStmt1
      public
        function assign_(const VarExpr, ValExpr: Expr): LoopBlockStmt1;
        function inc_(const VarExpr: Expr): LoopBlockStmt1; overload;
        function inc_(const VarExpr, ValExpr: Expr): LoopBlockStmt1; overload;
        function end_(): Stmt1;
        function while_(const WhileCondExpr: Expr): NestedWhileStmt2;
        function break_(): LoopBlockStmt1;
        function continue_(): LoopBlockStmt1;
      end;

      NestedStmtImpl2 = record helper for NestedStmt2
      public
        function assign_(const VarExpr, ValExpr: Expr): NestedStmt2;
        function while_(const WhileCondExpr: Expr): Prog.NestedWhileStmt2;
      end;
      NestedWhileStmtImpl2 = record helper for NestedWhileStmt2
      public
        function do_(): NestedLoopStmt2;
      end;
      NestedLoopStmtImpl2 = record helper for NestedLoopStmt2
      public
        function assign_(const VarExpr, ValExpr: Expr): NestedStmt2;
        function begin_(): NestedLoopBlockStmt2;
      end;
      NestedLoopBlockStmtImpl2 = record helper for NestedLoopBlockStmt2
      public
        function assign_(const VarExpr, ValExpr: Expr): NestedLoopBlockStmt2;
        function inc_(const VarExpr: Expr): NestedLoopBlockStmt2; overload;
        function inc_(const VarExpr, ValExpr: Expr): NestedLoopBlockStmt2; overload;
        function end_(): LoopBlockStmt1;
        function break_(): NestedLoopBlockStmt2;
        function continue_(): NestedLoopBlockStmt2;
      end;
  public
    procedure Accept(const Visitor: IStmtVisitor); overload;
    procedure Accept(const Transformer: IStmtTransformer); overload;

    class operator Implicit(const S: Stmt1): Prog;
  end;

  IAssignStmt = interface(IStmt)
    ['{E8EA83ED-5CE5-4E79-BCE0-EBE5731BE4F3}']
    function GetVariable: Expr;
    function GetValue: Expr;

    property Variable: Expr read GetVariable;
    property Value: Expr read GetValue;
  end;

  IBeginStmt = interface(IStmt)
    ['{831F0C42-AACE-4EAC-BE0D-A40FFF894E1F}']
  end;

  IEndStmt = interface(IStmt)
    ['{4788B0AE-BC92-4CCC-868E-17106164CFF6}']
  end;

  IIncStmt = interface(IStmt)
    ['{A13B837F-C55B-436F-9CCB-E4ACE933DFF4}']
    function GetVariable: Expr;
    function GetValue: Expr;

    property Variable: Expr read GetVariable;
    property Value: Expr read GetValue;
  end;

  IWhileStmt = interface(IStmt)
    ['{22E43859-2445-4201-B977-51FBEBF6D16A}']
    function GetWhileCondExpr: Expr;

    property WhileCondExpr: Expr read GetWhileCondExpr;
  end;

  IWhileDoStmt = interface(IStmt)
    ['{CB883CE3-CFEA-4624-966D-E49120D60705}']
  end;

  IBreakStmt = interface(IStmt)
    ['{0729E827-AD2A-4AA1-AC3D-6F2626677240}']
  end;

  IContinueStmt = interface(IStmt)
    ['{C2BEAEFF-1629-429C-B366-7365AF41BAC0}']
  end;

function assign_(const VarExpr, ValExpr: Expr): Prog.Stmt1;
function begin_(): Prog.Stmt1;
function while_(const WhileCondExpr: Expr): Prog.WhileStmt1;

procedure PrintProg(const p: Prog);

implementation

uses
  System.SysUtils;

type
  TStmtPrinter = class(TInterfacedObject, IStmtVisitor, IExprNodeVisitor)
  private
    FIndent: string;
    FHasIndented: boolean;

    procedure Output(const s: string);
    procedure NewLine();
    procedure Indent;
    procedure Unindent;
  public
    constructor Create;

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

procedure PrintProg(const p: Prog);
var
  printer: IStmtVisitor;
begin
  printer := TStmtPrinter.Create;
  p.Accept(printer);
end;

{ TStmtPrinter }

constructor TStmtPrinter.Create;
begin
  inherited Create;

  Indent;
end;

procedure TStmtPrinter.Indent;
begin
  FIndent := FIndent + '  ';
end;

procedure TStmtPrinter.NewLine;
begin
  WriteLn;
  FHasIndented := False;
end;

procedure TStmtPrinter.Output(const s: string);
begin
  if not FHasIndented then
  begin
    Write(FIndent);
    FHasIndented := True;
  end;
  Write(s);
end;

procedure TStmtPrinter.Unindent;
begin
  FIndent := Copy(FIndent, 1, Length(FIndent) - 2);
end;

procedure TStmtPrinter.Visit(const Stmt: IEndStmt);
begin
  Unindent;
  Output('}');
  NewLine;
end;

procedure TStmtPrinter.Visit(const Stmt: IIncStmt);
begin
  Stmt.Variable.Accept(Self);
  Output(' += ');
  Stmt.Value.Accept(Self);
  Output(';');
  NewLine;
end;

procedure TStmtPrinter.Visit(const Stmt: IAssignStmt);
begin
  Stmt.Variable.Accept(Self);
  Output(' = ');
  Stmt.Value.Accept(Self);
  Output(';');
  NewLine;
end;

procedure TStmtPrinter.Visit(const Stmt: IBeginStmt);
begin
  Output('{');
  Indent;
  NewLine;
end;

procedure TStmtPrinter.Visit(const Stmt: IBreakStmt);
begin
  Output('break;');
  NewLine;
end;

procedure TStmtPrinter.Visit(const Stmt: IContinueStmt);
begin
  Output('continue;');
  NewLine;
end;

procedure TStmtPrinter.Visit(const Stmt: IWhileStmt);
begin
  Output('while (');
  Stmt.WhileCondExpr.Accept(Self);
  Output(')');
end;

procedure TStmtPrinter.Visit(const Stmt: IWhileDoStmt);
begin
  NewLine;
end;

procedure TStmtPrinter.Visit(const Node: IArrayElementNode);
begin
  Output(Node.Data.Name);
  Output('[');
  Node.Data.Index.Accept(Self);
  Output(']');
end;

procedure TStmtPrinter.Visit(const Node: IVariableNode);
begin
  Output(Node.Data.Name);
end;

procedure TStmtPrinter.Visit(const Node: IConstantNode);
begin
  Output(Format('%.5g', [Node.Data.Value]));
end;

procedure TStmtPrinter.Visit(const Node: IFuncNode);
var
  i: integer;
begin
  Output(Node.Data.Name);
  Output('(');
  for i := 0 to Node.Data.ParamCount-1 do
  begin
    if (i > 0) then
      Output(', ');
    Node.Data.Params[i].Accept(Self);
  end;
  Output(')');
end;

procedure TStmtPrinter.Visit(const Node: IBinaryOpNode);
begin
  Output('(');
  Node.ChildNode1.Accept(Self);
  case Node.Op of
    boAdd: Output(' + ');
    boSub: Output(' - ');
    boMul: Output(' * ');
    boAnd: Output(' && ');
    boOr: Output(' || ');
    boEq: Output(' == ');
    boNotEq: Output(' != ');
    boLess: Output(' < ');
    boLessEq: Output(' <= ');
    boGreater: Output(' > ');
    boGreaterEq: Output(' >= ');
  end;
  Node.ChildNode2.Accept(Self);
  Output(')');
end;

procedure TStmtPrinter.Visit(const Node: IUnaryOpNode);
begin
  case Node.Op of
    uoNot: Output('!');
    uoNegate: Output('-');
  end;
  Output('(');
  Node.ChildNode.Accept(Self);
  Output(')');
end;

procedure TStmtPrinter.Visit(const Node: ILambdaParamNode);
begin
  Output(Node.Data.Name);
end;

type
  TBaseStmt = class(TInterfacedObject, IStmt)
  protected
    procedure DoAcceptVisitor(const Visitor: IStmtVisitor); virtual; abstract;
    function DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt; virtual; abstract;
  public
    procedure Accept(const Visitor: IStmtVisitor); overload;
    function Accept(const Transformer: IStmtTransformer): IStmt; overload;
  end;

  TAssignStmtImpl = class(TBaseStmt, IAssignStmt)
  strict private
    FVariable: Expr;
    FValue: Expr;
  protected
    procedure DoAcceptVisitor(const Visitor: IStmtVisitor); override;
    function DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt; override;
  public
    constructor Create(const VarExpr, ValExpr: Expr);

    function GetValue: Expr;
    function GetVariable: Expr;
  end;

  TBeginStmtImpl = class(TBaseStmt, IBeginStmt)
  protected
    procedure DoAcceptVisitor(const Visitor: IStmtVisitor); override;
    function DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt; override;
  end;

  TEndStmtImpl = class(TBaseStmt, IEndStmt)
  protected
    procedure DoAcceptVisitor(const Visitor: IStmtVisitor); override;
    function DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt; override;
  end;

  TIncStmtImpl = class(TBaseStmt, IIncStmt)
  strict private
    FVariable: Expr;
    FValue: Expr;
  protected
    procedure DoAcceptVisitor(const Visitor: IStmtVisitor); override;
    function DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt; override;
  public
    constructor Create(const VarExpr, ValExpr: Expr);

    function GetValue: Expr;
    function GetVariable: Expr;
  end;

  TWhileStmtImpl = class(TBaseStmt, IWhileStmt)
  strict private
    FWhileCondExpr: Expr;
  protected
    procedure DoAcceptVisitor(const Visitor: IStmtVisitor); override;
    function DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt; override;
  public
    constructor Create(const WhileCondExpr: Expr);

    function GetWhileCondExpr: Expr;
  end;

  TWhileDoStmtImpl = class(TBaseStmt, IWhileDoStmt)
  protected
    procedure DoAcceptVisitor(const Visitor: IStmtVisitor); override;
    function DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt; override;
  end;

  TBreakStmtImpl = class(TBaseStmt, IBreakStmt)
  protected
    procedure DoAcceptVisitor(const Visitor: IStmtVisitor); override;
    function DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt; override;
  end;

  TContinueStmtImpl = class(TBaseStmt, IContinueStmt)
  protected
    procedure DoAcceptVisitor(const Visitor: IStmtVisitor); override;
    function DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt; override;
  end;

function AddAssignStmt(const Stmts: StmtList; const VarExpr, ValExpr: Expr): StmtList;
begin
  result := Stmts;
  result.Add(TAssignStmtImpl.Create(VarExpr, ValExpr));
end;

function AddBeginStmt(const Stmts: StmtList): StmtList;
begin
  result := Stmts;
  result.Add(TBeginStmtImpl.Create);
end;

function AddEndStmt(const Stmts: StmtList): StmtList;
begin
  result := Stmts;
  result.Add(TEndStmtImpl.Create);
end;

function AddIncStmt(const Stmts: StmtList; const VarExpr, ValExpr: Expr): StmtList;
begin
  result := Stmts;
  result.Add(TIncStmtImpl.Create(VarExpr, ValExpr));
end;

function AddWhileStmt(const Stmts: StmtList; const WhileCondExpr: Expr): StmtList;
begin
  result := Stmts;
  result.Add(TWhileStmtImpl.Create(WhileCondExpr));
end;

function AddWhileDoStmt(const Stmts: StmtList): StmtList;
begin
  result := Stmts;
  result.Add(TWhileDoStmtImpl.Create);
end;

function AddBreakStmt(const Stmts: StmtList): StmtList;
begin
  result := Stmts;
  result.Add(TBreakStmtImpl.Create);
end;

function AddContinueStmt(const Stmts: StmtList): StmtList;
begin
  result := Stmts;
  result.Add(TContinueStmtImpl.Create);
end;

function NewStmtList: StmtList;
begin
  result := TListImpl<IStmt>.Create;
end;

function assign_(const VarExpr, ValExpr: Expr): Prog.Stmt1;
begin
  result.FStmtList := AddAssignStmt(NewStmtList, VarExpr, ValExpr);
end;

function begin_(): Prog.Stmt1;
begin
  result.FStmtList := AddBeginStmt(NewStmtList);
end;

function while_(const WhileCondExpr: Expr): Prog.WhileStmt1;
begin
  result.FStmtList := AddWhileStmt(NewStmtList, WhileCondExpr);
end;

{ TBaseStmt }

procedure TBaseStmt.Accept(const Visitor: IStmtVisitor);
begin
  DoAcceptVisitor(Visitor);
end;

function TBaseStmt.Accept(const Transformer: IStmtTransformer): IStmt;
begin
  result := DoAcceptTransformer(Transformer);
end;

{ TAssignStmtImpl }

constructor TAssignStmtImpl.Create(const VarExpr, ValExpr: Expr);
begin
  inherited Create;

  FVariable := VarExpr;
  FValue := ValExpr;
end;

function TAssignStmtImpl.DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt;
var
  s: IAssignStmt;
begin
  s := Self;
  result := Transformer.Transform(s);
end;

procedure TAssignStmtImpl.DoAcceptVisitor(const Visitor: IStmtVisitor);
var
  s: IAssignStmt;
begin
  s := Self;
  Visitor.Visit(s);
end;

function TAssignStmtImpl.GetValue: Expr;
begin
  result := FValue;
end;

function TAssignStmtImpl.GetVariable: Expr;
begin
  result := FVariable;
end;

{ TBeginStmtImpl }

function TBeginStmtImpl.DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt;
var
  s: IBeginStmt;
begin
  s := Self;
  result := Transformer.Transform(s);
end;

procedure TBeginStmtImpl.DoAcceptVisitor(const Visitor: IStmtVisitor);
var
  s: IBeginStmt;
begin
  s := Self;
  Visitor.Visit(s);
end;

{ TBreakStmtImpl }

function TBreakStmtImpl.DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt;
var
  s: IBreakStmt;
begin
  s := Self;
  result := Transformer.Transform(s);
end;

procedure TBreakStmtImpl.DoAcceptVisitor(const Visitor: IStmtVisitor);
var
  s: IBreakStmt;
begin
  s := Self;
  Visitor.Visit(Self);
end;

{ TContinueStmtImpl }

function TContinueStmtImpl.DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt;
begin
  result := Transformer.Transform(Self);
end;

procedure TContinueStmtImpl.DoAcceptVisitor(const Visitor: IStmtVisitor);
begin
  Visitor.Visit(Self);
end;

{ TEndStmtImpl }

function TEndStmtImpl.DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt;
begin
  result := Transformer.Transform(Self);
end;

procedure TEndStmtImpl.DoAcceptVisitor(const Visitor: IStmtVisitor);
begin
  Visitor.Visit(Self);
end;

{ TIncStmtImpl }

constructor TIncStmtImpl.Create(const VarExpr, ValExpr: Expr);
begin
  inherited Create;

  FVariable := VarExpr;
  FValue := ValExpr;
end;

function TIncStmtImpl.DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt;
begin
  result := Transformer.Transform(Self);
end;

procedure TIncStmtImpl.DoAcceptVisitor(const Visitor: IStmtVisitor);
begin
  Visitor.Visit(Self);
end;

function TIncStmtImpl.GetValue: Expr;
begin
  result := FValue;
end;

function TIncStmtImpl.GetVariable: Expr;
begin
  result := FVariable;
end;

{ TWhileStmtImpl }

constructor TWhileStmtImpl.Create(const WhileCondExpr: Expr);
begin
  inherited Create;

  FWhileCondExpr := WhileCondExpr;
end;

function TWhileStmtImpl.DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt;
begin
  result := Transformer.Transform(Self);
end;

procedure TWhileStmtImpl.DoAcceptVisitor(const Visitor: IStmtVisitor);
begin
  Visitor.Visit(Self);
end;

function TWhileStmtImpl.GetWhileCondExpr: Expr;
begin
  result := FWhileCondExpr;
end;

{ TWhileDoStmtImpl }

function TWhileDoStmtImpl.DoAcceptTransformer(const Transformer: IStmtTransformer): IStmt;
begin
  result := Transformer.Transform(Self);
end;

procedure TWhileDoStmtImpl.DoAcceptVisitor(const Visitor: IStmtVisitor);
begin
  Visitor.Visit(Self);
end;

{ Prog }

procedure Prog.Accept(const Visitor: IStmtVisitor);
var
  i: integer;
begin
  for i := 0 to FStmtList.Count-1 do
    FStmtList[i].Accept(Visitor);
end;

procedure Prog.Accept(const Transformer: IStmtTransformer);
var
  i: integer;
begin
  for i := 0 to FStmtList.Count-1 do
    FStmtList[i] := FStmtList[i].Accept(Transformer);
end;

class operator Prog.Implicit(const S: Stmt1): Prog;
begin
  result.FStmtList := S.FStmtList;
end;

{ Prog.StmtImpl }

function Prog.StmtImpl1.assign_(const VarExpr, ValExpr: Expr): Prog.Stmt1;
begin
  result.FStmtList := AddAssignStmt(FStmtList, VarExpr, ValExpr);
end;

function Prog.StmtImpl1.inc_(const VarExpr: Expr): Stmt1;
begin
  result := inc_(VarExpr, 1.0);
end;

function Prog.StmtImpl1.inc_(const VarExpr, ValExpr: Expr): Stmt1;
begin
  result.FStmtList := AddIncStmt(FStmtList, VarExpr, ValExpr);
end;

function Prog.StmtImpl1.while_(const WhileCondExpr: Expr): Prog.WhileStmt1;
begin
  result.FStmtList := AddWhileStmt(FStmtList, WhileCondExpr);
end;

{ Prog.WhileStmtImpl }

function Prog.WhileStmtImpl1.do_: Prog.LoopStmt1;
begin
  result.FStmtList := AddWhileDoStmt(FStmtList);
end;

{ Prog.LoopStmtImpl }

function Prog.LoopStmtImpl1.assign_(const VarExpr, ValExpr: Expr): Prog.Stmt1;
begin
  result.FStmtList := AddBeginStmt(FStmtList);
  result.FStmtList := AddAssignStmt(FStmtList, VarExpr, ValExpr);
  result.FStmtList := AddEndStmt(FStmtList);
end;

function Prog.LoopStmtImpl1.begin_: Prog.LoopBlockStmt1;
begin
  result.FStmtList := AddBeginStmt(FStmtList);
end;

{ Prog.LoopBlockStmtImpl1 }

function Prog.LoopBlockStmtImpl1.assign_(const VarExpr, ValExpr: Expr): LoopBlockStmt1;
begin
  result.FStmtList := AddAssignStmt(FStmtList, VarExpr, ValExpr);
end;

function Prog.LoopBlockStmtImpl1.break_: LoopBlockStmt1;
begin
  result.FStmtList := AddBreakStmt(FStmtList);
end;

function Prog.LoopBlockStmtImpl1.continue_: LoopBlockStmt1;
begin
  result.FStmtList := AddContinueStmt(FStmtList);
end;

function Prog.LoopBlockStmtImpl1.end_: Stmt1;
begin
  result.FStmtList := AddEndStmt(FStmtList);
end;

function Prog.LoopBlockStmtImpl1.inc_(const VarExpr: Expr): LoopBlockStmt1;
begin
  result := inc_(VarExpr, 1.0);
end;

function Prog.LoopBlockStmtImpl1.inc_(const VarExpr, ValExpr: Expr): LoopBlockStmt1;
begin
  result.FStmtList := AddIncStmt(FStmtList, VarExpr, ValExpr);
end;

function Prog.LoopBlockStmtImpl1.while_(const WhileCondExpr: Expr): NestedWhileStmt2;
begin
  result.FStmtList := AddWhileStmt(FStmtList, WhileCondExpr);
end;

{ Prog.NestedStmtImpl2 }

function Prog.NestedStmtImpl2.assign_(const VarExpr, ValExpr: Expr): NestedStmt2;
begin
  result.FStmtList := AddBeginStmt(FStmtList);
  result.FStmtList := AddAssignStmt(FStmtList, VarExpr, ValExpr);
  result.FStmtList := AddEndStmt(FStmtList);
end;

function Prog.NestedStmtImpl2.while_(const WhileCondExpr: Expr): Prog.NestedWhileStmt2;
begin
  result.FStmtList := AddWhileStmt(FStmtList, WhileCondExpr);
end;

{ Prog.NestedWhileStmtImpl2 }

function Prog.NestedWhileStmtImpl2.do_: NestedLoopStmt2;
begin
  result.FStmtList := AddWhileDoStmt(FStmtList);
end;

{ Prog.NestedLoopStmtImpl2 }

function Prog.NestedLoopStmtImpl2.assign_(const VarExpr, ValExpr: Expr): NestedStmt2;
begin
  result.FStmtList := AddBeginStmt(FStmtList);
  result.FStmtList := AddAssignStmt(FStmtList, VarExpr, ValExpr);
  result.FStmtList := AddEndStmt(FStmtList);
end;

function Prog.NestedLoopStmtImpl2.begin_: NestedLoopBlockStmt2;
begin
  result.FStmtList := AddBeginStmt(FStmtList);
end;

{ Prog.NestedLoopBlockStmtImpl2 }

function Prog.NestedLoopBlockStmtImpl2.assign_(const VarExpr, ValExpr: Expr): NestedLoopBlockStmt2;
begin
  result.FStmtList := AddAssignStmt(FStmtList, VarExpr, ValExpr);
end;

function Prog.NestedLoopBlockStmtImpl2.break_: NestedLoopBlockStmt2;
begin
  result.FStmtList := AddBreakStmt(FStmtList);
end;

function Prog.NestedLoopBlockStmtImpl2.continue_: NestedLoopBlockStmt2;
begin
  result.FStmtList := AddContinueStmt(FStmtList);
end;

function Prog.NestedLoopBlockStmtImpl2.end_: LoopBlockStmt1;
begin
  result.FStmtList := AddEndStmt(FStmtList);
end;

function Prog.NestedLoopBlockStmtImpl2.inc_(const VarExpr: Expr): NestedLoopBlockStmt2;
begin
  result := inc_(VarExpr, 1.0);
end;

function Prog.NestedLoopBlockStmtImpl2.inc_(const VarExpr, ValExpr: Expr): NestedLoopBlockStmt2;
begin
  result.FStmtList := AddIncStmt(FStmtList, VarExpr, ValExpr);
end;


end.
