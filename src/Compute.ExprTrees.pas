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

unit Compute.ExprTrees;

interface

type
  IExprNodeVisitor = interface;
  IExprNodeTransformer = interface;

  IExprNode = interface
    ['{1220E127-F6B9-44AF-8F60-267C56E20F76}']
    procedure Accept(const Visitor: IExprNodeVisitor); overload;
    function Accept(const Transformer: IExprNodeTransformer): IExprNode; overload;
  end;

  IConstantNode = interface;

  IVariableNode = interface;

  IArrayElementNode = interface;

  IUnaryOpNode = interface;

  IBinaryOpNode = interface;

  IFuncNode = interface;

  ILambdaParamNode = interface;

  IExprNodeVisitor = interface
    ['{BACAD5B1-B34A-4DA6-B87F-F7BE8D853F93}']
    procedure Visit(const Node: IConstantNode); overload;
    procedure Visit(const Node: IVariableNode); overload;
    procedure Visit(const Node: IArrayElementNode); overload;
    procedure Visit(const Node: IUnaryOpNode); overload;
    procedure Visit(const Node: IBinaryOpNode); overload;
    procedure Visit(const Node: IFuncNode); overload;
    procedure Visit(const Node: ILambdaParamNode); overload;
  end;

  IExprNodeTransformer = interface
    ['{96D4249B-D6D3-45FB-B867-384220EA82D9}']
    function Transform(const Node: IConstantNode): IExprNode; overload;
    function Transform(const Node: IVariableNode): IExprNode; overload;
    function Transform(const Node: IArrayElementNode): IExprNode; overload;
    function Transform(const Node: IUnaryOpNode): IExprNode; overload;
    function Transform(const Node: IBinaryOpNode): IExprNode; overload;
    function Transform(const Node: IFuncNode): IExprNode; overload;
    function Transform(const Node: ILambdaParamNode): IExprNode; overload;
  end;

  Expr = record
  strict private
    FNode: IExprNode;
  public
    type
      BuiltInFuncBody = record
      private
        class function Create: BuiltInFuncBody; static;
      end;

      Constant = record
      strict private
        FValue: double;
      private
        class function Create(const Value: double): Constant; static;
      public
        property Value: double read FValue;
      end;

      Variable = record
      strict private
        FName: string;
      private
        class function Create(const Name: string): Variable; static;
      public
        property Name: string read FName;

        class operator Negative(const Value: Expr.Variable): Expr;

        class operator Add(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator Add(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator Add(const Value1, Value2: Expr.Variable): Expr;

        class operator Subtract(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator Subtract(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator Subtract(const Value1, Value2: Expr.Variable): Expr;

        class operator Multiply(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator Multiply(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator Multiply(const Value1, Value2: Expr.Variable): Expr;

        class operator Divide(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator Divide(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator Divide(const Value1, Value2: Expr.Variable): Expr;

        class operator Equal(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator Equal(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator Equal(const Value1, Value2: Expr.Variable): Expr;

        class operator NotEqual(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator NotEqual(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator NotEqual(const Value1, Value2: Expr.Variable): Expr;

        class operator GreaterThan(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator GreaterThan(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator GreaterThan(const Value1, Value2: Expr.Variable): Expr;

        class operator GreaterThanOrEqual(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator GreaterThanOrEqual(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator GreaterThanOrEqual(const Value1, Value2: Expr.Variable): Expr;

        class operator LessThan(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator LessThan(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator LessThan(const Value1, Value2: Expr.Variable): Expr;

        class operator LessThanOrEqual(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator LessThanOrEqual(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator LessThanOrEqual(const Value1, Value2: Expr.Variable): Expr;

        class operator BitwiseAnd(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator BitwiseAnd(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator BitwiseAnd(const Value1, Value2: Expr.Variable): Expr;

        class operator BitwiseOr(const Value1: Expr.Variable; const Value2: double): Expr;
        class operator BitwiseOr(const Value1: double; const Value2: Expr.Variable): Expr;
        class operator BitwiseOr(const Value1, Value2: Expr.Variable): Expr;
      end;

      ArrayElement = record
      strict private
        FName: string;
        FCount: integer;
        FIndex: TArray<Expr>; // workaround, Expr is incomplete
      private
        class function Create(const Name: string; const Count: integer; const Index: Expr): ArrayElement; static;
        function GetIndex: Expr;
      public
        property Name: string read FName;
        property Count: integer read FCount;
        property Index: Expr read GetIndex;

        class operator Negative(const Value: Expr.ArrayElement): Expr;

        class operator Add(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator Add(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator Add(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator Add(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator Add(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator Subtract(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator Subtract(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator Subtract(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator Subtract(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator Subtract(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator Multiply(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator Multiply(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator Multiply(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator Multiply(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator Multiply(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator Divide(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator Divide(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator Divide(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator Divide(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator Divide(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator Equal(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator Equal(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator Equal(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator Equal(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator Equal(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator NotEqual(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator NotEqual(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator NotEqual(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator NotEqual(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator NotEqual(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator GreaterThan(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator GreaterThan(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator GreaterThan(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator GreaterThan(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator GreaterThan(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator GreaterThanOrEqual(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator GreaterThanOrEqual(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator GreaterThanOrEqual(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator LessThan(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator LessThan(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator LessThan(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator LessThan(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator LessThan(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator LessThanOrEqual(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator LessThanOrEqual(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator LessThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator LessThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator LessThanOrEqual(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator BitwiseAnd(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator BitwiseAnd(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator BitwiseAnd(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator BitwiseAnd(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator BitwiseAnd(const Value1, Value2: Expr.ArrayElement): Expr;

        class operator BitwiseOr(const Value1: Expr.ArrayElement; const Value2: double): Expr;
        class operator BitwiseOr(const Value1: double; const Value2: Expr.ArrayElement): Expr;
        class operator BitwiseOr(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
        class operator BitwiseOr(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
        class operator BitwiseOr(const Value1, Value2: Expr.ArrayElement): Expr;
      end;

      ArrayVariable = record
      strict private
        FName: string;
        FCount: integer;
      private
        class function Create(const Name: string; const Count: integer): ArrayVariable; static;
        function GetElement(const Index: Expr): ArrayElement;
      public
        property Name: string read FName;
        property Count: integer read FCount;
        property Element[const Index: Expr]: ArrayElement read GetElement; default;
      end;

      NaryFunc = record
      strict private
        FName: string;
        FBody: TArray<Expr>;
        FParamCount: integer;
        FParams: TArray<Expr>;
      private
        class function Create(const Name: string; const Body, Param: Expr): NaryFunc; overload; static;
        class function Create(const Name: string; const Body, Param1, Param2: Expr): NaryFunc; overload; static;
        function GetBody: Expr;
        function GetParam(const Index: integer): Expr;
        function GetIsBuiltIn: boolean;
      public
        property Name: string read FName;
        property Body: Expr read GetBody;
        property ParamCount: integer read FParamCount;
        property Params[const Index: integer]: Expr read GetParam;
        property IsBuiltIn: boolean read GetIsBuiltIn;

        class operator Negative(const Value: Expr.NaryFunc): Expr;

        class operator Add(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator Add(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator Add(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator Add(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator Add(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator Add(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator Add(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator Subtract(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator Subtract(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator Subtract(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator Subtract(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator Subtract(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator Subtract(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator Subtract(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator Multiply(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator Multiply(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator Multiply(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator Multiply(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator Multiply(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator Multiply(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator Multiply(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator Divide(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator Divide(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator Divide(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator Divide(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator Divide(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator Divide(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator Divide(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator Equal(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator Equal(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator Equal(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator Equal(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator Equal(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator Equal(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator Equal(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator NotEqual(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator NotEqual(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator NotEqual(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator NotEqual(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator NotEqual(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator NotEqual(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator NotEqual(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator GreaterThan(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator GreaterThan(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator GreaterThan(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator GreaterThan(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator GreaterThan(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator GreaterThan(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator GreaterThan(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator GreaterThanOrEqual(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator GreaterThanOrEqual(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator GreaterThanOrEqual(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator LessThan(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator LessThan(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator LessThan(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator LessThan(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator LessThan(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator LessThan(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator LessThan(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator LessThanOrEqual(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator LessThanOrEqual(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator LessThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator LessThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator LessThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator LessThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator LessThanOrEqual(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator BitwiseAnd(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator BitwiseAnd(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator BitwiseAnd(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator BitwiseAnd(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator BitwiseAnd(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator BitwiseAnd(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator BitwiseAnd(const Value1, Value2: Expr.NaryFunc): Expr;

        class operator BitwiseOr(const Value1: Expr.NaryFunc; const Value2: double): Expr;
        class operator BitwiseOr(const Value1: double; const Value2: Expr.NaryFunc): Expr;
        class operator BitwiseOr(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
        class operator BitwiseOr(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
        class operator BitwiseOr(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
        class operator BitwiseOr(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
        class operator BitwiseOr(const Value1, Value2: Expr.NaryFunc): Expr;
      end;

      Func1 = reference to function(const Param: Expr): NaryFunc;
      Func2 = reference to function(const Param1, Param2: Expr): NaryFunc;

      LambdaParam = record
      strict private
        FName: string;
      private
        class function Create(const Name: string): LambdaParam; overload; static;
      public
        property Name: string read FName;

        class operator Negative(const Value: Expr.LambdaParam): Expr;

        class operator Add(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator Add(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator Add(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator Add(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator Add(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator Add(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator Add(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator Add(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator Add(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator Subtract(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator Subtract(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator Subtract(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator Subtract(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator Subtract(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator Subtract(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator Subtract(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator Subtract(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator Subtract(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator Multiply(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator Multiply(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator Multiply(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator Multiply(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator Multiply(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator Multiply(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator Multiply(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator Multiply(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator Multiply(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator Divide(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator Divide(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator Divide(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator Divide(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator Divide(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator Divide(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator Divide(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator Divide(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator Divide(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator Equal(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator Equal(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator Equal(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator Equal(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator Equal(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator Equal(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator Equal(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator Equal(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator Equal(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator NotEqual(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator NotEqual(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator NotEqual(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator NotEqual(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator NotEqual(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator NotEqual(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator NotEqual(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator NotEqual(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator NotEqual(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator GreaterThan(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator GreaterThan(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator GreaterThan(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator GreaterThan(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator GreaterThan(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator GreaterThan(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator GreaterThan(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator GreaterThan(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator GreaterThan(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator GreaterThanOrEqual(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator GreaterThanOrEqual(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator GreaterThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator GreaterThanOrEqual(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator LessThan(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator LessThan(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator LessThan(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator LessThan(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator LessThan(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator LessThan(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator LessThan(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator LessThan(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator LessThan(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator LessThanOrEqual(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator LessThanOrEqual(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator LessThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator LessThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator LessThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator LessThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator LessThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator LessThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator LessThanOrEqual(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator BitwiseAnd(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator BitwiseAnd(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator BitwiseAnd(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator BitwiseAnd(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator BitwiseAnd(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator BitwiseAnd(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator BitwiseAnd(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator BitwiseAnd(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator BitwiseAnd(const Value1, Value2: Expr.LambdaParam): Expr;

        class operator BitwiseOr(const Value1: Expr.LambdaParam; const Value2: double): Expr;
        class operator BitwiseOr(const Value1: double; const Value2: Expr.LambdaParam): Expr;
        class operator BitwiseOr(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
        class operator BitwiseOr(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
        class operator BitwiseOr(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
        class operator BitwiseOr(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
        class operator BitwiseOr(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
        class operator BitwiseOr(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
        class operator BitwiseOr(const Value1, Value2: Expr.LambdaParam): Expr;
      end;
  public
    procedure Accept(const Visitor: IExprNodeVisitor); overload;
    procedure Accept(const Transformer: IExprNodeTransformer); overload;

    property Node: IExprNode read FNode;

    class operator Implicit(const Value: BuiltInFuncBody): Expr;
    class operator Implicit(const Value: double): Expr;
    class operator Implicit(const Value: Constant): Expr;
    class operator Implicit(const Value: Variable): Expr;
    class operator Implicit(const Value: ArrayElement): Expr;
    class operator Implicit(const Value: NaryFunc): Expr;
    class operator Implicit(const Value: LambdaParam): Expr;

    class operator Negative(const Value: Expr): Expr;

    class operator Add(const Value1, Value2: Expr): Expr;
    class operator Subtract(const Value1, Value2: Expr): Expr;
    class operator Multiply(const Value1, Value2: Expr): Expr;
    class operator Divide(const Value1, Value2: Expr): Expr;
    class operator Equal(const Value1, Value2: Expr): Expr;
    class operator NotEqual(const Value1, Value2: Expr): Expr;
    class operator GreaterThan(const Value1, Value2: Expr): Expr;
    class operator GreaterThanOrEqual(const Value1, Value2: Expr): Expr;
    class operator LessThan(const Value1, Value2: Expr): Expr;
    class operator LessThanOrEqual(const Value1, Value2: Expr): Expr;
    class operator BitwiseAnd(const Value1, Value2: Expr): Expr;
    class operator BitwiseOr(const Value1, Value2: Expr): Expr;
  end;

  IConstantNode = interface(IExprNode)
    ['{6D54E9CE-0830-4FF6-9249-3F07215FD63B}']
    function GetData: Expr.Constant;

    property Data: Expr.Constant read GetData;
  end;

  IVariableNode = interface(IExprNode)
    ['{8C5762F3-D681-4F1A-8CBE-0AEF692486A3}']
    function GetData: Expr.Variable;

    property Data: Expr.Variable read GetData;
  end;

  IArrayElementNode = interface(IExprNode)
    ['{8C5762F3-D681-4F1A-8CBE-0AEF692486A3}']
    function GetData: Expr.ArrayElement;

    property Data: Expr.ArrayElement read GetData;
  end;

  UnaryOpType = (uoNot, uoNegate);
  IUnaryOpNode = interface(IExprNode)
    ['{7FDA9F1B-7BF4-4AE7-9C4E-7A5F743C8C3E}']
    function GetOp: UnaryOpType;
    function GetChildNode: IExprNode;

    property Op: UnaryOpType read GetOp;
    property ChildNode: IExprNode read GetChildNode;
  end;

  BinaryOpType = (boAdd, boSub, boMul, boDiv, boAnd, boOr, boXor, boEq, boNotEq, boLess, boLessEq, boGreater, boGreaterEq);
  IBinaryOpNode = interface(IExprNode)
    ['{7CBC4576-FBDF-4562-8E46-F2658B8DDC79}']
    function GetOp: BinaryOpType;
    function GetChildNode1: IExprNode;
    function GetChildNode2: IExprNode;

    property Op: BinaryOpType read GetOp;
    property ChildNode1: IExprNode read GetChildNode1;
    property ChildNode2: IExprNode read GetChildNode2;
  end;

  IFuncNode = interface(IExprNode)
    ['{1CB93C6D-AD4F-4E1F-8775-7FD67A40EBFA}']
    function GetData: Expr.NaryFunc;

    property Data: Expr.NaryFunc read GetData;
  end;

  ILambdaParamNode = interface(IExprNode)
    ['{3B92D89A-3FFF-4737-B6B4-A8228FD6D79C}']
    function GetData: Expr.LambdaParam;

    property Data: Expr.LambdaParam read GetData;
  end;

type
  TExprNodeBase = class(TInterfacedObject, IExprNode)
  protected
    procedure DoAcceptVisitor(const Visitor: IExprNodeVisitor); virtual; abstract;
    function DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode; virtual; abstract;
  public
    procedure Accept(const Visitor: IExprNodeVisitor); overload;
    function Accept(const Transformer: IExprNodeTransformer): IExprNode; overload;
  end;

  TConstantNodeImpl = class(TExprNodeBase, IConstantNode)
  strict private
    FData: Expr.Constant;
  protected
    procedure DoAcceptVisitor(const Visitor: IExprNodeVisitor); override;
    function DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode; override;
  public
    constructor Create(const Data: Expr.Constant);

    function GetData: Expr.Constant;
  end;

  TVariableNodeImpl = class(TExprNodeBase, IVariableNode)
  strict private
    FData: Expr.Variable;
  protected
    procedure DoAcceptVisitor(const Visitor: IExprNodeVisitor); override;
    function DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode; override;
  public
    constructor Create(const Data: Expr.Variable);

    function GetData: Expr.Variable;
  end;

  TArrayElementNodeImpl = class(TExprNodeBase, IArrayElementNode)
  strict private
    FData: Expr.ArrayElement;
  protected
    procedure DoAcceptVisitor(const Visitor: IExprNodeVisitor); override;
    function DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode; override;
  public
    constructor Create(const Data: Expr.ArrayElement);

    function GetData: Expr.ArrayElement;
  end;

  TUnaryOpNodeImpl = class(TExprNodeBase, IUnaryOpNode)
  strict private
    FOp: UnaryOpType;
    FChild: IExprNode;
  protected
    procedure DoAcceptVisitor(const Visitor: IExprNodeVisitor); override;
    function DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode; override;
  public
    constructor Create(const Op: UnaryOpType; const Child: IExprNode);

    function GetChildNode: IExprNode;
    function GetOp: UnaryOpType;
  end;

  TBinaryOpNodeImpl = class(TExprNodeBase, IBinaryOpNode)
  strict private
    FOp: BinaryOpType;
    FChild1: IExprNode;
    FChild2: IExprNode;
  protected
    procedure DoAcceptVisitor(const Visitor: IExprNodeVisitor); override;
    function DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode; override;
  public
    constructor Create(const Op: BinaryOpType; const Child1, Child2: IExprNode);

    function GetChildNode1: IExprNode;
    function GetChildNode2: IExprNode;
    function GetOp: BinaryOpType;
  end;

  TFuncNodeImpl = class(TExprNodeBase, IFuncNode)
  strict private
    FData: Expr.NaryFunc;
  protected
    procedure DoAcceptVisitor(const Visitor: IExprNodeVisitor); override;
    function DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode; override;
  public
    constructor Create(const Data: Expr.NaryFunc);

    function GetData: Expr.NaryFunc;
  end;

  TLambdaParamNodeImpl = class(TExprNodeBase, ILambdaParamNode)
  strict private
    FData: Expr.LambdaParam;
  protected
    procedure DoAcceptVisitor(const Visitor: IExprNodeVisitor); override;
    function DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode; override;
  public
    constructor Create(const Data: Expr.LambdaParam);

    function GetData: Expr.LambdaParam;
  end;

function __BuiltInFuncBody: Expr.BuiltInFuncBody;

function Constant(const Value: double): Expr.Constant;
function Variable(const Name: string): Expr.Variable;
function ArrayVariable(const Name: string; const Count: integer): Expr.ArrayVariable;
function Func1(const Name: string; const FuncBody: Expr): Expr.Func1;
function Func2(const Name: string; const FuncBody: Expr): Expr.Func2;
function _1: Expr.LambdaParam;
function _2: Expr.LambdaParam;

procedure PrintExpr(const e: Expr);

implementation

uses
  System.SysUtils;

function __BuiltInFuncBody: Expr.BuiltInFuncBody;
begin
  result := Expr.BuiltInFuncBody.Create;
end;

function Constant(const Value: double): Expr.Constant;
begin
  result := Expr.Constant.Create(Value);
end;

function Variable(const Name: string): Expr.Variable;
begin
  result := Expr.Variable.Create(Name);
end;

function ArrayVariable(const Name: string; const Count: integer): Expr.ArrayVariable;
begin
  result := Expr.ArrayVariable.Create(Name, Count);
end;

function Func1(const Name: string; const FuncBody: Expr): Expr.Func1;
begin
  result :=
    function(const Param: Expr): Expr.NaryFunc
    begin
      result := Expr.NaryFunc.Create(Name, FuncBody, Param);
    end;
end;

function Func2(const Name: string; const FuncBody: Expr): Expr.Func2;
begin
  result :=
    function(const Param1, Param2: Expr): Expr.NaryFunc
    begin
      result := Expr.NaryFunc.Create(Name, FuncBody, Param1, Param2);
    end;
end;

function _1: Expr.LambdaParam;
begin
  result := Expr.LambdaParam.Create('_1');
end;

function _2: Expr.LambdaParam;
begin
  result := Expr.LambdaParam.Create('_2');
end;

type
  TExprPrinter = class(TInterfacedObject, IExprNodeVisitor)
  private
    procedure Output(const s: string);
  public
    procedure Visit(const Node: IConstantNode); overload;
    procedure Visit(const Node: IVariableNode); overload;
    procedure Visit(const Node: IArrayElementNode); overload;
    procedure Visit(const Node: IUnaryOpNode); overload;
    procedure Visit(const Node: IBinaryOpNode); overload;
    procedure Visit(const Node: IFuncNode); overload;
    procedure Visit(const Node: ILambdaParamNode); overload;
  end;

procedure PrintExpr(const e: Expr);
var
  printer: IExprNodeVisitor;
begin
  printer := TExprPrinter.Create;
  e.Accept(printer);
end;

{ TExprPrinter }

procedure TExprPrinter.Visit(const Node: IVariableNode);
begin
  Output(Node.Data.Name);
end;

procedure TExprPrinter.Visit(const Node: IConstantNode);
begin
  Output(Format('%.3f', [Node.Data.Value]));
end;

procedure TExprPrinter.Visit(const Node: IUnaryOpNode);
begin
  case Node.Op of
    uoNot: Output('!');
    uoNegate: Output('-');
  else
    raise ENotImplemented.Create('Unknown unary operator');
  end;
  Output('(');
  Node.ChildNode.Accept(Self);
  Output(')');
end;

procedure TExprPrinter.Output(const s: string);
begin
  Write(s);
end;

procedure TExprPrinter.Visit(const Node: IArrayElementNode);
begin
  Output(Node.Data.Name);
  Output('[');
  Node.Data.Index.Accept(Self);
  Output(']');
end;

procedure TExprPrinter.Visit(const Node: IFuncNode);
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

procedure TExprPrinter.Visit(const Node: IBinaryOpNode);
begin
  Output('(');
  Node.ChildNode1.Accept(Self);
  case Node.Op of
    boAdd: Output(' + ');
    boSub: Output(' - ');
    boMul: Output(' * ');
    boDiv: Output(' / ');
    boAnd: Output(' && ');
    boOr: Output(' || ');
    boEq: Output(' == ');
    boNotEq: Output(' != ');
    boLess: Output(' < ');
    boLessEq: Output(' <= ');
    boGreater: Output(' > ');
    boGreaterEq: Output(' >= ');
  else
    raise ENotImplemented.Create('Unknown binary operator');
  end;
  Node.ChildNode2.Accept(Self);
  Output(')');
end;

procedure TExprPrinter.Visit(const Node: ILambdaParamNode);
begin
  Output(Node.Data.Name);
end;

{ Expr.BuiltInFuncBody }

class function Expr.BuiltInFuncBody.Create: BuiltInFuncBody;
begin
  //
end;

{ Expr.Constant }

class function Expr.Constant.Create(const Value: double): Expr.Constant;
begin
  result.FValue := Value;
end;

{ Expr.Variable }

class function Expr.Variable.Create(const Name: string): Expr.Variable;
begin
  result.FName := Name;
end;

class operator Expr.Variable.Negative(const Value: Expr.Variable): Expr;
begin
  result := -Expr(Value);
end;

class operator Expr.Variable.Add(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.Variable.Add(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.Variable.Add(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.Variable.Subtract(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.Variable.Subtract(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.Variable.Subtract(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.Variable.Multiply(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.Variable.Multiply(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.Variable.Multiply(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.Variable.Divide(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.Variable.Divide(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.Variable.Divide(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.Variable.Equal(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.Variable.Equal(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.Variable.Equal(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.Variable.NotEqual(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.Variable.NotEqual(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.Variable.NotEqual(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.Variable.GreaterThan(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.Variable.GreaterThan(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.Variable.GreaterThan(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.Variable.GreaterThanOrEqual(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.Variable.GreaterThanOrEqual(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.Variable.GreaterThanOrEqual(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.Variable.LessThan(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.Variable.LessThan(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.Variable.LessThan(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.Variable.LessThanOrEqual(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.Variable.LessThanOrEqual(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.Variable.LessThanOrEqual(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.Variable.BitwiseAnd(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.Variable.BitwiseAnd(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.Variable.BitwiseAnd(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.Variable.BitwiseOr(const Value1: Expr.Variable; const Value2: double): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.Variable.BitwiseOr(const Value1: double; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.Variable.BitwiseOr(const Value1, Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

{ Expr.ArrayElement }

class function Expr.ArrayElement.Create(const Name: string; const Count: integer; const Index: Expr): Expr.ArrayElement;
begin
  result.FName := Name;
  result.FCount := Count;
  SetLength(result.FIndex, 1);
  result.FIndex[0] := Index;
end;

function Expr.ArrayElement.GetIndex: Expr;
begin
  result := FIndex[0];
end;

class operator Expr.ArrayElement.Negative(const Value: Expr.ArrayElement): Expr;
begin
  result := -Expr(Value);
end;

class operator Expr.ArrayElement.Add(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.ArrayElement.Add(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.ArrayElement.Add(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.ArrayElement.Add(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.ArrayElement.Add(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.ArrayElement.Subtract(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.ArrayElement.Subtract(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.ArrayElement.Subtract(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.ArrayElement.Subtract(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.ArrayElement.Subtract(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.ArrayElement.Multiply(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.ArrayElement.Multiply(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.ArrayElement.Multiply(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.ArrayElement.Multiply(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.ArrayElement.Multiply(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.ArrayElement.Divide(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.ArrayElement.Divide(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.ArrayElement.Divide(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.ArrayElement.Divide(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.ArrayElement.Divide(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.ArrayElement.Equal(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.ArrayElement.Equal(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.ArrayElement.Equal(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.ArrayElement.Equal(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.ArrayElement.Equal(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.ArrayElement.NotEqual(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.ArrayElement.NotEqual(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.ArrayElement.NotEqual(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.ArrayElement.NotEqual(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.ArrayElement.NotEqual(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThan(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThan(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThan(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThan(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThan(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThanOrEqual(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThanOrEqual(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.ArrayElement.GreaterThanOrEqual(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.ArrayElement.LessThan(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.ArrayElement.LessThan(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.ArrayElement.LessThan(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.ArrayElement.LessThan(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.ArrayElement.LessThan(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.ArrayElement.LessThanOrEqual(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.ArrayElement.LessThanOrEqual(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.ArrayElement.LessThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.ArrayElement.LessThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.ArrayElement.LessThanOrEqual(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseAnd(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseAnd(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseAnd(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseAnd(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseAnd(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseOr(const Value1: Expr.ArrayElement; const Value2: double): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseOr(const Value1: double; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseOr(const Value1: Expr.ArrayElement; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseOr(const Value1: Expr.Variable; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.ArrayElement.BitwiseOr(const Value1, Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

{ Expr.ArrayVariable }

class function Expr.ArrayVariable.Create(const Name: string; const Count: integer): Expr.ArrayVariable;
begin
  result.FName := Name;
  result.FCount := Count;
end;

function Expr.ArrayVariable.GetElement(const Index: Expr): Expr.ArrayElement;
begin
  result := ArrayElement.Create(Name, Count, Index);
end;

{ Expr.NaryFunc }

class function Expr.NaryFunc.Create(const Name: string; const Body, Param: Expr): Expr.NaryFunc;
begin
  result.FName := Name;
  SetLength(result.FBody, 1);
  result.FBody[0] := Body;
  result.FParamCount := 1;
  SetLength(result.FParams, result.FParamCount);
  result.FParams[0] := Param;
end;

class function Expr.NaryFunc.Create(const Name: string; const Body, Param1, Param2: Expr): Expr.NaryFunc;
begin
  result.FName := Name;
  SetLength(result.FBody, 1);
  result.FBody[0] := Body;
  result.FParamCount := 2;
  SetLength(result.FParams, result.FParamCount);
  result.FParams[0] := Param1;
  result.FParams[1] := Param2;
end;

function Expr.NaryFunc.GetBody: Expr;
begin
  result := FBody[0];
end;

function Expr.NaryFunc.GetParam(const Index: integer): Expr;
begin
  result := FParams[Index];
end;

function Expr.NaryFunc.GetIsBuiltIn: boolean;
begin
  result := Body.Node = nil;
end;

class operator Expr.NaryFunc.Negative(const Value: Expr.NaryFunc): Expr;
begin
  result := -Expr(Value);
end;

class operator Expr.NaryFunc.Add(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.NaryFunc.Add(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.NaryFunc.Add(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.NaryFunc.Add(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.NaryFunc.Add(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.NaryFunc.Add(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.NaryFunc.Add(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.NaryFunc.Subtract(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.NaryFunc.Subtract(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.NaryFunc.Subtract(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.NaryFunc.Subtract(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.NaryFunc.Subtract(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.NaryFunc.Subtract(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.NaryFunc.Subtract(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.NaryFunc.Multiply(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.NaryFunc.Multiply(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.NaryFunc.Multiply(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.NaryFunc.Multiply(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.NaryFunc.Multiply(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.NaryFunc.Multiply(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.NaryFunc.Multiply(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.NaryFunc.Divide(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.NaryFunc.Divide(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.NaryFunc.Divide(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.NaryFunc.Divide(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.NaryFunc.Divide(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.NaryFunc.Divide(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.NaryFunc.Divide(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.NaryFunc.Equal(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.NaryFunc.Equal(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.NaryFunc.Equal(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.NaryFunc.Equal(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.NaryFunc.Equal(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.NaryFunc.Equal(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.NaryFunc.Equal(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.NaryFunc.NotEqual(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.NaryFunc.NotEqual(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.NaryFunc.NotEqual(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.NaryFunc.NotEqual(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.NaryFunc.NotEqual(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.NaryFunc.NotEqual(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.NaryFunc.NotEqual(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThan(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThan(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThan(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThan(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThan(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThan(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThan(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThanOrEqual(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThanOrEqual(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.NaryFunc.GreaterThanOrEqual(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.NaryFunc.LessThan(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.NaryFunc.LessThan(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.NaryFunc.LessThan(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.NaryFunc.LessThan(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.NaryFunc.LessThan(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.NaryFunc.LessThan(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.NaryFunc.LessThan(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.NaryFunc.LessThanOrEqual(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.NaryFunc.LessThanOrEqual(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.NaryFunc.LessThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.NaryFunc.LessThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.NaryFunc.LessThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.NaryFunc.LessThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.NaryFunc.LessThanOrEqual(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseAnd(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseAnd(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseAnd(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseAnd(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseAnd(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseAnd(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseAnd(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseOr(const Value1: Expr.NaryFunc; const Value2: double): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseOr(const Value1: double; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseOr(const Value1: Expr.NaryFunc; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseOr(const Value1: Expr.Variable; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseOr(const Value1: Expr.NaryFunc; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseOr(const Value1: Expr.ArrayElement; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.NaryFunc.BitwiseOr(const Value1, Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;


{ Expr.LambdaParam }

class function Expr.LambdaParam.Create(const Name: string): LambdaParam;
begin
  result.FName := Name;
end;

class operator Expr.LambdaParam.Negative(const Value: Expr.LambdaParam): Expr;
begin
  result := -Expr(Value);
end;

class operator Expr.LambdaParam.Add(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.LambdaParam.Add(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.LambdaParam.Add(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.LambdaParam.Add(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.LambdaParam.Add(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.LambdaParam.Add(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.LambdaParam.Add(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.LambdaParam.Add(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.LambdaParam.Add(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) + Expr(Value2);
end;

class operator Expr.LambdaParam.Subtract(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.LambdaParam.Subtract(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.LambdaParam.Subtract(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.LambdaParam.Subtract(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.LambdaParam.Subtract(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.LambdaParam.Subtract(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.LambdaParam.Subtract(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.LambdaParam.Subtract(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.LambdaParam.Subtract(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) - Expr(Value2);
end;

class operator Expr.LambdaParam.Multiply(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.LambdaParam.Multiply(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.LambdaParam.Multiply(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.LambdaParam.Multiply(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.LambdaParam.Multiply(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.LambdaParam.Multiply(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.LambdaParam.Multiply(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.LambdaParam.Multiply(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.LambdaParam.Multiply(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) * Expr(Value2);
end;

class operator Expr.LambdaParam.Divide(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.LambdaParam.Divide(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.LambdaParam.Divide(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.LambdaParam.Divide(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.LambdaParam.Divide(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.LambdaParam.Divide(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.LambdaParam.Divide(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.LambdaParam.Divide(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.LambdaParam.Divide(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) / Expr(Value2);
end;

class operator Expr.LambdaParam.Equal(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.LambdaParam.Equal(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.LambdaParam.Equal(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.LambdaParam.Equal(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.LambdaParam.Equal(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.LambdaParam.Equal(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.LambdaParam.Equal(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.LambdaParam.Equal(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.LambdaParam.Equal(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) = Expr(Value2);
end;

class operator Expr.LambdaParam.NotEqual(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.LambdaParam.NotEqual(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.LambdaParam.NotEqual(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.LambdaParam.NotEqual(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.LambdaParam.NotEqual(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.LambdaParam.NotEqual(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.LambdaParam.NotEqual(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.LambdaParam.NotEqual(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.LambdaParam.NotEqual(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <> Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThan(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThan(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThan(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThan(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThan(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThan(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThan(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThan(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThan(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) > Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThanOrEqual(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThanOrEqual(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.LambdaParam.GreaterThanOrEqual(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) >= Expr(Value2);
end;

class operator Expr.LambdaParam.LessThan(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.LambdaParam.LessThan(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.LambdaParam.LessThan(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.LambdaParam.LessThan(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.LambdaParam.LessThan(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.LambdaParam.LessThan(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.LambdaParam.LessThan(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.LambdaParam.LessThan(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.LambdaParam.LessThan(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) < Expr(Value2);
end;

class operator Expr.LambdaParam.LessThanOrEqual(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.LambdaParam.LessThanOrEqual(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.LambdaParam.LessThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.LambdaParam.LessThanOrEqual(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.LambdaParam.LessThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.LambdaParam.LessThanOrEqual(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.LambdaParam.LessThanOrEqual(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.LambdaParam.LessThanOrEqual(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.LambdaParam.LessThanOrEqual(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) <= Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseAnd(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseAnd(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseAnd(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseAnd(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseAnd(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseAnd(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseAnd(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseAnd(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseAnd(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) and Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseOr(const Value1: Expr.LambdaParam; const Value2: double): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseOr(const Value1: double; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseOr(const Value1: Expr.LambdaParam; const Value2: Expr.Variable): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseOr(const Value1: Expr.Variable; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseOr(const Value1: Expr.LambdaParam; const Value2: Expr.ArrayElement): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseOr(const Value1: Expr.ArrayElement; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseOr(const Value1: Expr.LambdaParam; const Value2: Expr.NaryFunc): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseOr(const Value1: Expr.NaryFunc; const Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

class operator Expr.LambdaParam.BitwiseOr(const Value1, Value2: Expr.LambdaParam): Expr;
begin
  result := Expr(Value1) or Expr(Value2);
end;

{ TExpr }

procedure Expr.Accept(const Visitor: IExprNodeVisitor);
begin
  if Assigned(FNode) then
    FNode.Accept(Visitor);
end;

procedure Expr.Accept(const Transformer: IExprNodeTransformer);
begin
  if Assigned(FNode) then
    FNode := FNode.Accept(Transformer);
end;

class operator Expr.Add(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boAdd, Value1.FNode, Value2.FNode);
end;

class operator Expr.BitwiseAnd(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boAnd, Value1.FNode, Value2.FNode);
end;

class operator Expr.BitwiseOr(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boOr, Value1.FNode, Value2.FNode);
end;

class operator Expr.Divide(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boDiv, Value1.FNode, Value2.FNode);
end;

class operator Expr.Equal(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boEq, Value1.FNode, Value2.FNode);
end;

class operator Expr.GreaterThan(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boGreater, Value1.FNode, Value2.FNode);
end;

class operator Expr.GreaterThanOrEqual(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boGreaterEq, Value1.FNode, Value2.FNode);
end;

class operator Expr.Implicit(const Value: Expr.Constant): Expr;
begin
  result.FNode := TConstantNodeImpl.Create(Value);
end;

class operator Expr.Implicit(const Value: Expr.Variable): Expr;
begin
  result.FNode := TVariableNodeImpl.Create(Value);
end;

class operator Expr.Implicit(const Value: double): Expr;
begin
  result := Expr.Constant.Create(Value);
end;

class operator Expr.Implicit(const Value: NaryFunc): Expr;
begin
  result.FNode := TFuncNodeImpl.Create(Value);
end;

class operator Expr.LessThan(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boLess, Value1.FNode, Value2.FNode);
end;

class operator Expr.LessThanOrEqual(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boLessEq, Value1.FNode, Value2.FNode);
end;

class operator Expr.Implicit(const Value: ArrayElement): Expr;
begin
  result.FNode := TArrayElementNodeImpl.Create(Value);
end;

class operator Expr.Implicit(const Value: LambdaParam): Expr;
begin
  result.FNode := TLambdaParamNodeImpl.Create(Value);
end;

class operator Expr.Implicit(const Value: BuiltInFuncBody): Expr;
begin
  // empty body
  result.FNode := nil;
end;

class operator Expr.Multiply(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boMul, Value1.FNode, Value2.FNode);
end;

class operator Expr.Negative(const Value: Expr): Expr;
begin
  result.FNode := TUnaryOpNodeImpl.Create(uoNegate, Value.FNode);
end;

class operator Expr.NotEqual(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boNotEq, Value1.FNode, Value2.FNode);
end;

class operator Expr.Subtract(const Value1, Value2: Expr): Expr;
begin
  result.FNode := TBinaryOpNodeImpl.Create(boSub, Value1.FNode, Value2.FNode);
end;

{ TExprNodeBase }

procedure TExprNodeBase.Accept(const Visitor: IExprNodeVisitor);
begin
  DoAcceptVisitor(Visitor);
end;

function TExprNodeBase.Accept(const Transformer: IExprNodeTransformer): IExprNode;
begin
  result := DoAcceptTransformer(Transformer);
end;

{ TConstantNodeImpl }

constructor TConstantNodeImpl.Create(const Data: Expr.Constant);
begin
  inherited Create;

  FData := Data;
end;

function TConstantNodeImpl.DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode;
begin
  result := Transformer.Transform(Self);
end;

procedure TConstantNodeImpl.DoAcceptVisitor(const Visitor: IExprNodeVisitor);
begin
  Visitor.Visit(Self);
end;

function TConstantNodeImpl.GetData: Expr.Constant;
begin
  result := FData;
end;

{ TVariableNodeImpl }

constructor TVariableNodeImpl.Create(const Data: Expr.Variable);
begin
  inherited Create;

  FData := Data;
end;

function TVariableNodeImpl.DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode;
begin
  result := Transformer.Transform(Self);
end;

procedure TVariableNodeImpl.DoAcceptVisitor(const Visitor: IExprNodeVisitor);
begin
  Visitor.Visit(Self);
end;

function TVariableNodeImpl.GetData: Expr.Variable;
begin
  result := FData;
end;

{ TArrayElementNodeImpl }

constructor TArrayElementNodeImpl.Create(const Data: Expr.ArrayElement);
begin
  inherited Create;

  FData := Data;
end;

function TArrayElementNodeImpl.DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode;
begin
  result := Transformer.Transform(Self);
end;

procedure TArrayElementNodeImpl.DoAcceptVisitor(const Visitor: IExprNodeVisitor);
begin
  Visitor.Visit(Self);
end;

function TArrayElementNodeImpl.GetData: Expr.ArrayElement;
begin
  result := FData;
end;

{ TUnaryOpNodeImpl }

constructor TUnaryOpNodeImpl.Create(const Op: UnaryOpType; const Child: IExprNode);
begin
  inherited Create;

  FOp := Op;
  FChild := Child;
end;

function TUnaryOpNodeImpl.DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode;
begin
  result := Transformer.Transform(Self);
end;

procedure TUnaryOpNodeImpl.DoAcceptVisitor(const Visitor: IExprNodeVisitor);
begin
  Visitor.Visit(Self);
end;

function TUnaryOpNodeImpl.GetChildNode: IExprNode;
begin
  result := FChild;
end;

function TUnaryOpNodeImpl.GetOp: UnaryOpType;
begin
  result := FOp;
end;

{ TBinaryOpNodeImpl }

constructor TBinaryOpNodeImpl.Create(const Op: BinaryOpType; const Child1, Child2: IExprNode);
begin
  inherited Create;

  FOp := Op;
  FChild1 := Child1;
  FChild2 := Child2;
end;

function TBinaryOpNodeImpl.DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode;
begin
  result := Transformer.Transform(Self);
end;

procedure TBinaryOpNodeImpl.DoAcceptVisitor(const Visitor: IExprNodeVisitor);
begin
  Visitor.Visit(Self);
end;

function TBinaryOpNodeImpl.GetChildNode1: IExprNode;
begin
  result := FChild1;
end;

function TBinaryOpNodeImpl.GetChildNode2: IExprNode;
begin
  result := FChild2;
end;

function TBinaryOpNodeImpl.GetOp: BinaryOpType;
begin
  result := FOp;
end;

{ TFuncNodeImpl }

constructor TFuncNodeImpl.Create(const Data: Expr.NaryFunc);
begin
  inherited Create;

  FData := Data;
end;

function TFuncNodeImpl.DoAcceptTransformer(const Transformer: IExprNodeTransformer): IExprNode;
begin
  result := Transformer.Transform(Self);
end;

procedure TFuncNodeImpl.DoAcceptVisitor(const Visitor: IExprNodeVisitor);
begin
  Visitor.Visit(Self);
end;

function TFuncNodeImpl.GetData: Expr.NaryFunc;
begin
  result := FData;
end;

{ TLambdaParamNodeImpl }

constructor TLambdaParamNodeImpl.Create(const Data: Expr.LambdaParam);
begin
  inherited Create;

  FData := Data;
end;

function TLambdaParamNodeImpl.DoAcceptTransformer(
  const Transformer: IExprNodeTransformer): IExprNode;
begin
  result := Transformer.Transform(Self);
end;

procedure TLambdaParamNodeImpl.DoAcceptVisitor(const Visitor: IExprNodeVisitor);
begin
  Visitor.Visit(Self);
end;

function TLambdaParamNodeImpl.GetData: Expr.LambdaParam;
begin
  result := FData;
end;

end.
