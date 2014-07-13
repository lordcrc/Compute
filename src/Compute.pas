unit Compute;

interface

uses
  Compute.Common,
  Compute.ExprTrees;

type
  Expr = Compute.ExprTrees.Expr;

function Constant(const Value: double): Expr.Constant;
function Variable(const Name: string): Expr.Variable;
function ArrayVariable(const Name: string; const Count: integer): Expr.ArrayVariable;
function Func1(const Name: string; const FuncBody: Expr): Expr.Func1;
function Func2(const Name: string; const FuncBody: Expr): Expr.Func2;
function _1: Expr.LambdaParam;
function _2: Expr.LambdaParam;

type
  IFuture<T> = interface
    function GetDone: boolean;
    function GetValue: T;

    procedure Wait;

    property Done: boolean read GetDone;
    property Value: T read GetValue;
  end;

procedure InitializeCompute;

function AsyncTransform(const Input: TArray<double>; const Expression: Expr): IFuture<TArray<double>>;
function Transform(const Input: TArray<double>; const Expression: Expr): TArray<double>;

implementation

uses
  Compute.OpenCL, Winapi.Windows, System.SysUtils,
  Compute.OpenCL.KernelGenerator, System.Math;

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

function _1: Expr.LambdaParam;
begin
  result := Compute.ExprTrees._1;
end;

function _2: Expr.LambdaParam;
begin
  result := Compute.ExprTrees._2;
end;

type
  TOpenCLFutureImpl<T> = class(TInterfacedObject, IFuture<T>)
  strict private
    FValue: T;
    FContext: CLContext;
    FEvent: CLEvent;
  public
    // Value must be reference type
    constructor Create(const Context: CLContext; const Event: CLEvent; const Value: T);

    function GetDone: boolean;
    function GetValue: T;
    procedure Wait;

    property Context: CLContext read FContext;
    property Event: CLEvent read FEvent;
  end;


{ TOpenCLFutureImpl<T> }

constructor TOpenCLFutureImpl<T>.Create(const Context: CLContext;
  const Event: CLEvent; const Value: T);
begin
  inherited Create;

  FContext := Context;
  FEvent := Event;
  FValue := Value;
end;

function TOpenCLFutureImpl<T>.GetDone: boolean;
begin
  result := (Event.CommandExecutionStatus = ExecutionStatusComplete);
end;

function TOpenCLFutureImpl<T>.GetValue: T;
begin
  result := FValue;
end;

procedure TOpenCLFutureImpl<T>.Wait;
begin
  Context.WaitForEvents([Event]);
end;

type
  IComputeAlgorithms = interface
    procedure Initialize;

    function Transform(const Input, Result: TArray<double>; const Expression: Expr): IFuture<TArray<double>>; overload;
  end;

  TComputeAlgorithmsOpenCLImpl = class(TInterfacedObject, IComputeAlgorithms)
  strict private
    FDevice: CLDevice;
    FContext: CLContext;
    FQueue: CLCommandQueue;

    procedure Initialize;

    function Transform(const Input, Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>; overload;

    property Device: CLDevice read FDevice;
    property Context: CLContext read FContext;
    property Queue: CLCommandQueue read FQueue;
  public
    constructor Create;
  end;

var
  _AlgorithmsImpl: IComputeAlgorithms;

procedure InitializeAlgorithmsImpl;
var
  alg: IComputeAlgorithms;
begin
  alg := TComputeAlgorithmsOpenCLImpl.Create;

  if (AtomicCmpExchange(pointer(_AlgorithmsImpl), pointer(alg), nil) = nil) then
  begin
    // successfully updated _Algorithms, so manually bump reference count
    alg._AddRef;
  end;
end;

function Algorithms: IComputeAlgorithms;
begin
  result := _AlgorithmsImpl;

  if (result <> nil) then
    exit;

  InitializeAlgorithmsImpl;

  result := _AlgorithmsImpl;
end;

procedure InitializeCompute;
begin
  Algorithms.Initialize;
end;

function AsyncTransform(const Input: TArray<double>; const Expression: Expr): IFuture<TArray<double>>;
var
  output: TArray<double>;
begin
  SetLength(output, Length(Input));

  result := Algorithms.Transform(Input, output, Expression);
end;

function Transform(const Input: TArray<double>; const Expression: Expr): TArray<double>;
var
  f: IFuture<TArray<double>>;
begin
  f := AsyncTransform(Input, Expression);
  f.Wait;
  result := f.Value;
end;

{ TComputeAlgorithmsOpenCLImpl }

constructor TComputeAlgorithmsOpenCLImpl.Create;
var
  debugLogger: TLogProc;
  platforms: CLPlatforms;
  plat: CLPlatform;
  foundDevice: boolean;
  dev, selectedDev: CLDevice;
begin
  inherited Create;

//  debugLogger :=
//    procedure(const Msg: string)
//    begin
//      OutputDebugString(PChar(Msg));
//    end;
  debugLogger := nil;

  platforms := CLPlatforms.Create(debugLogger);
  plat := platforms[0];

  foundDevice := False;
  if Length(plat.Devices[DeviceTypeGPU]) > 0 then
  begin
    for dev in plat.Devices[DeviceTypeGPU] do
    begin
      if not (dev.SupportsFP64 and dev.IsAvailable) then
        continue;

      if (not foundDevice) or (dev.MaxMemAllocSize > selectedDev.MaxMemAllocSize)
        or (dev.MaxComputeUnits > selectedDev.MaxComputeUnits) then
      begin
        selectedDev := dev;
        foundDevice := True;
      end;
    end;
  end;
//  if Length(plat.Devices[DeviceTypeCPU]) > 0 then
//  begin
//    for dev in plat.Devices[DeviceTypeCPU] do
//    begin
//      if not (dev.SupportsFP64 and dev.IsAvailable) then
//        continue;
//
//      if (not foundDevice) or (dev.MaxMemAllocSize > selectedDev.MaxMemAllocSize)
//        or (dev.MaxComputeUnits > selectedDev.MaxComputeUnits) then
//      begin
//        selectedDev := dev;
//        foundDevice := True;
//      end;
//    end;
//  end;

  if (not foundDevice) then
  begin
    for dev in plat.AllDevices do
    begin
      if not (dev.SupportsFP64 and dev.IsAvailable) then
        continue;

      if (not foundDevice) or (dev.MaxComputeUnits > selectedDev.MaxComputeUnits)
        or (dev.MaxMemAllocSize > selectedDev.MaxMemAllocSize) then
      begin
        selectedDev := dev;
        foundDevice := True;
      end;
    end;
  end;

  if (not foundDevice) then
    raise ENotSupportedException.Create('No suitable OpenCL device found');

  FDevice := selectedDev;

  FContext := plat.CreateContext([FDevice]);
  FQueue := FContext.CreateCommandQueue(FDevice);
end;

procedure TComputeAlgorithmsOpenCLImpl.Initialize;
begin
  // not much for now
end;

function TComputeAlgorithmsOpenCLImpl.Transform(const Input,
  Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>;
var
  srcBuffer, resBuffer: CLBuffer;
  prog: CLProgram;
  kernel: CLKernel;
  kernelSrc: string;
  kernelGen: IKernelGenerator;
  workGroupSize: UInt32;
  globalWorkSize: UInt64;
  event: CLEvent;
begin
  if (Length(Input) <> Length(Output)) then
    raise EArgumentException.Create('Transform: Input length is not equal to output length');

  srcBuffer := Context.CreateDeviceBuffer(BufferAccessReadOnly, Length(Input) * SizeOf(double));
  resBuffer := Context.CreateDeviceBuffer(BufferAccessWriteOnly, srcBuffer.Size);

  kernelGen := DefaultKernelGenerator;
  kernelSrc := kernelGen.GenerateDoubleTransformKernel(Expression);

  prog := Context.CreateProgram(kernelSrc);
  if not prog.Build([Device]) then
  begin
    raise Exception.Create('Error building OpenCL source:' + #13#10 + prog.BuildLog);
  end;

  kernel := prog.CreateKernel('transform_double');

  kernel.Arguments[0] := srcBuffer;
  kernel.Arguments[1] := resBuffer;
  kernel.Arguments[2] := Length(Input);

  workGroupSize := kernel.PreferredWorkgroupSizeMultiple;

  if (workGroupSize > 1) then
  begin
    globalWorkSize := workGroupSize * UInt32(Ceil(Length(Input) / workGroupSize));
  end
  else
  begin
    globalWorkSize := Length(Input);
  end;

  event := Queue.EnqueueWriteBuffer(srcBuffer, BufferCommmandNonBlocking, 0, srcBuffer.Size, Input, []);
  event := Queue.Enqueue1DRangeKernel(kernel, Range1D(0), Range1D(globalWorkSize), Range1D(workGroupSize), [event]);
  event := Queue.EnqueueReadBuffer(resBuffer, BufferCommmandNonBlocking, 0, resBuffer.Size, Output, [event]);

  result := TOpenCLFutureImpl<TArray<double>>.Create(Context, event, Output);
end;

end.
