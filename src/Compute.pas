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

unit Compute;

interface

uses
  Compute.Common,
  Compute.ExprTrees,
  Compute.OpenCL,
  Compute.Future.Detail;

type
  Expr = Compute.ExprTrees.Expr;

  Buffer<T> = record
  strict private
    FCmdQueue: Compute.OpenCL.CLCommandQueue;
    FBuffer: Compute.OpenCL.CLBuffer;

    function GetNumElements: UInt64;
    function GetSize: UInt64;
  private
    property CmdQueue: Compute.OpenCL.CLCommandQueue read FCmdQueue;
    property Buffer: Compute.OpenCL.CLBuffer read FBuffer;
  public
    class function Create(const NumElements: UInt64): Buffer<T>; overload; static;
    class function Create(const InitialData: TArray<T>): Buffer<T>; overload; static;

    procedure CopyTo(const DestBuffer: Buffer<T>);
    procedure SwapWith(var OtherBuffer: Buffer<T>);

    function ToArray: TArray<T>;

    property NumElements: UInt64 read GetNumElements;
    property Size: UInt64 read GetSize;

    // underlying buffer
    property Handle: Compute.OpenCL.CLBuffer read FBuffer;
  end;

  Future<T> = record
  strict private
    FImpl: IFuture<T>;
    function GetDone: boolean;
    function GetValue: T;
  private
    class function CreateReady(const Value: T): Future<T>; static;

    property Impl: IFuture<T> read FImpl;
  public
    class operator Implicit(const Impl: IFuture<T>): Future<T>;
    // makes a ready-future
    class operator Implicit(const Value: T): Future<T>;

    procedure SwapWith(var OtherFuture: Future<T>);

    procedure Wait;

    property Done: boolean read GetDone;
    property Value: T read GetValue;
  end;

function Constant(const Value: double): Expr.Constant;
function Variable(const Name: string): Expr.Variable;
function ArrayVariable(const Name: string; const Count: integer): Expr.ArrayVariable;
function Func1(const Name: string; const FuncBody: Expr): Expr.Func1;
function Func2(const Name: string; const FuncBody: Expr): Expr.Func2;
function Func3(const Name: string; const FuncBody: Expr): Expr.Func3;
function _1: Expr.LambdaParam;
function _2: Expr.LambdaParam;
function _3: Expr.LambdaParam;

procedure InitializeCompute;

function AsyncTransform(const InputBuffer: Buffer<double>; const Expression: Expr): Future<Buffer<double>>; overload;
// queues the async transform to execute as soon as the input buffer is ready, output buffer is returned in the future
function AsyncTransform(const InputBuffer, OutputBuffer: Future<Buffer<double>>; const Expression: Expr): Future<Buffer<double>>; overload;

// two inputs
function AsyncTransform(const InputBuffer1, InputBuffer2, OutputBuffer: Future<Buffer<double>>; const Expression: Expr): Future<Buffer<double>>; overload;

// three inputs
function AsyncTransform(const InputBuffer1, InputBuffer2, InputBuffer3, OutputBuffer: Future<Buffer<double>>; const Expression: Expr): Future<Buffer<double>>; overload;


function AsyncTransform(const Input: TArray<double>; const Expression: Expr): Future<TArray<double>>; overload;
function Transform(const Input: TArray<double>; const Expression: Expr): TArray<double>;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Math,
  Compute.Detail;

function Constant(const Value: double): Expr.Constant;
begin
  result := Compute.ExprTrees.Constant(Value);
end;

function Variable(const Name: string): Expr.Variable;
begin
  result := Compute.ExprTrees.Variable(Name);
end;

function ArrayVariable(const Name: string; const Count: integer): Expr.ArrayVariable;
begin
  result := Compute.ExprTrees.ArrayVariable(Name, Count);
end;

function Func1(const Name: string; const FuncBody: Expr): Expr.Func1;
begin
  result := Compute.ExprTrees.Func1(Name, FuncBody);
end;

function Func2(const Name: string; const FuncBody: Expr): Expr.Func2;
begin
  result := Compute.ExprTrees.Func2(Name, FuncBody);
end;

function Func3(const Name: string; const FuncBody: Expr): Expr.Func3;
begin
  result := Compute.ExprTrees.Func3(Name, FuncBody);
end;

function _1: Expr.LambdaParam;
begin
  result := Compute.ExprTrees._1;
end;

function _2: Expr.LambdaParam;
begin
  result := Compute.ExprTrees._2;
end;

function _3: Expr.LambdaParam;
begin
  result := Compute.ExprTrees._3;
end;

{ Future<T> }

class function Future<T>.CreateReady(const Value: T): Future<T>;
begin
  result.FImpl := TReadyFutureImpl<T>.Create(Value);
end;

function Future<T>.GetDone: boolean;
begin
  result := Impl.Done;
end;

function Future<T>.GetValue: T;
begin
  result := Impl.Value;
end;

class operator Future<T>.Implicit(const Value: T): Future<T>;
begin
  result := CreateReady(Value);
end;

procedure Future<T>.SwapWith(var OtherFuture: Future<T>);
var
  f: IFuture<T>;
begin
  f := OtherFuture.FImpl;
  OtherFuture.FImpl := FImpl;
  FImpl := f;
end;

class operator Future<T>.Implicit(const Impl: IFuture<T>): Future<T>;
begin
  result.FImpl := Impl;
end;

procedure Future<T>.Wait;
begin
  Impl.Wait;
end;

procedure InitializeCompute;
begin
  Algorithms.Initialize;
end;

{ Buffer<T> }

class function Buffer<T>.Create(const NumElements: UInt64): Buffer<T>;
begin
  result.FCmdQueue := Algorithms.CmdQueue;
  result.FBuffer := Algorithms.Context.CreateHostBuffer(BufferAccessReadWrite, SizeOf(T) * NumElements);
end;

class function Buffer<T>.Create(const InitialData: TArray<T>): Buffer<T>;
var
  size: UInt64;
begin
  size := SizeOf(T) * Length(InitialData);
  result.FCmdQueue := Algorithms.CmdQueue;
  result.FBuffer := Algorithms.Context.CreateHostBuffer(BufferAccessReadWrite, size, InitialData);
end;

function Buffer<T>.GetNumElements: UInt64;
begin
  result := FBuffer.Size div SizeOf(T);
end;

function Buffer<T>.GetSize: UInt64;
begin
  result := FBuffer.Size;
end;

procedure Buffer<T>.SwapWith(var OtherBuffer: Buffer<T>);
var
  t: CLBuffer;
begin
  t := OtherBuffer.FBuffer;
  OtherBuffer.FBuffer := FBuffer;
  FBuffer := t;
end;

function Buffer<T>.ToArray: TArray<T>;
var
  len: UInt64;
begin
  len := NumElements;
  SetLength(result, len);

  FCmdQueue.EnqueueReadBuffer(FBuffer, BufferCommandBlocking, 0, len * SizeOf(T), result, []);
end;

procedure Buffer<T>.CopyTo(const DestBuffer: Buffer<T>);
var
  event: CLEvent;
begin
  event := DestBuffer.CmdQueue.EnqueueCopyBuffer(
    Buffer,
    DestBuffer.Buffer,
    0, 0,
    Min(Buffer.Size, DestBuffer.Buffer.Size), []);

  event.Wait;
end;

function AsyncTransform(const InputBuffer: Buffer<double>; const Expression: Expr): Future<Buffer<double>>;
var
  outputBuffer: Buffer<double>;
begin
  outputBuffer := Buffer<double>.Create(InputBuffer.NumElements);

  result := AsyncTransform(InputBuffer, outputBuffer, Expression);
end;

function AsyncTransform(const Input: TArray<double>; const Expression: Expr): Future<TArray<double>>;
var
  output: TArray<double>;
begin
  SetLength(output, Length(Input));

  result := Algorithms.Transform(Input, output, Expression);
end;

function Transform(const Input: TArray<double>; const Expression: Expr): TArray<double>;
var
  f: Future<TArray<double>>;
begin
  f := AsyncTransform(Input, Expression);
  result := f.Value;
end;

function AsyncTransform(const InputBuffer, OutputBuffer: Future<Buffer<double>>; const Expression: Expr): Future<Buffer<double>>;
begin
  result := Algorithms.Transform(InputBuffer.Impl, 0, InputBuffer.Impl.PeekValue.NumElements, OutputBuffer.Impl, Expression);
end;

function AsyncTransform(const InputBuffer1, InputBuffer2, OutputBuffer: Future<Buffer<double>>; const Expression: Expr): Future<Buffer<double>>;
begin
  result := Algorithms.Transform([InputBuffer1.Impl, InputBuffer2.Impl], 0, InputBuffer1.Impl.PeekValue.NumElements, OutputBuffer.Impl, Expression);
end;

function AsyncTransform(const InputBuffer1, InputBuffer2, InputBuffer3, OutputBuffer: Future<Buffer<double>>; const Expression: Expr): Future<Buffer<double>>;
begin
  result := Algorithms.Transform([InputBuffer1.Impl, InputBuffer2.Impl, InputBuffer3.Impl], 0, InputBuffer1.Impl.PeekValue.NumElements, OutputBuffer.Impl, Expression);
end;

end.
