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
    FCmdQueue: CLCommandQueue;
    FMemReadQueue: CLCommandQueue;
    FMemWriteQueue: CLCommandQueue;

    function DeviceOptimalNonInterleavedBufferSize: UInt64;
    function DeviceOptimalInterleavedBufferSize: UInt64;

    procedure Initialize;

    function TransformPlain(const Input, Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>; overload;
    function TransformInterleaved(const Input, Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>; overload;

    function Transform(const Input, Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>; overload;

    property Device: CLDevice read FDevice;
    property Context: CLContext read FContext;
    property CmdQueue: CLCommandQueue read FCmdQueue;
    property MemReadQueue: CLCommandQueue read FMemReadQueue;
    property MemWriteQueue: CLCommandQueue read FMemWriteQueue;
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
begin
  inherited Create;
end;

function TComputeAlgorithmsOpenCLImpl.DeviceOptimalInterleavedBufferSize: UInt64;
begin
  // for now some magic numbers
  // to be replaced by something better
  if Device.IsType[DeviceTypeCPU] then
    result := 32
  else if Device.IsType[DeviceTypeGPU] then
    result := 32
  else
    result := 32;

  result := result * 1024 * 1024;
end;

function TComputeAlgorithmsOpenCLImpl.DeviceOptimalNonInterleavedBufferSize: UInt64;
begin
  // for now some magic numbers
  // to be replaced by something better
  if Device.IsType[DeviceTypeCPU] then
    result := 32
  else if Device.IsType[DeviceTypeGPU] then
    result := 128
  else
    result := 32;

  result := result * 1024 * 1024;
end;

procedure TComputeAlgorithmsOpenCLImpl.Initialize;
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
  if true and (Length(plat.Devices[DeviceTypeGPU]) > 0) then
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
  if (not foundDevice) and (Length(plat.Devices[DeviceTypeCPU]) > 0) then
  begin
    for dev in plat.Devices[DeviceTypeCPU] do
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

  if IsConsole then
    WriteLn('Selected device: ' + FDevice.Name);

  FContext := plat.CreateContext([FDevice]);
  FCmdQueue := FContext.CreateCommandQueue(FDevice);
  FMemReadQueue := FContext.CreateCommandQueue(FDevice);
  FMemWriteQueue := FContext.CreateCommandQueue(FDevice);
end;

function TComputeAlgorithmsOpenCLImpl.Transform(const Input,
  Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>;
begin
  if (Length(Input) <> Length(Output)) then
    raise EArgumentException.Create('Transform: Input length is not equal to output length');

  //if (Length(Input) <= 256 * 1024 * 1024) then
  //result := TransformPlain(Input, Output, Expression);
  result := TransformInterleaved(Input, Output, Expression);
end;

function TComputeAlgorithmsOpenCLImpl.TransformInterleaved(const Input,
  Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>;
var
  vectorWidth, vectorSize: UInt32;
  inputSize, bufferSize: UInt64;
  srcBuffer, resBuffer: array[0..1] of CLBuffer;
  prog: CLProgram;
  kernel: CLKernel;
  kernelSrc: string;
  kernelGen: IKernelGenerator;
  workGroupSize: UInt32;
  globalWorkSize: UInt64;
  writeEvent, execEvent, readEvent: array[0..1] of CLEvent;
  bufferOffset, bufferRemaining, workItemOffset: UInt64;
  current_idx: integer;
begin
  vectorWidth := Max(1, Device.PreferredVectorWidthDouble);
  inputSize := Length(Input) * SizeOf(double);
  bufferSize := Min(DeviceOptimalInterleavedBufferSize, inputSize);
  vectorSize := SizeOf(double) * vectorWidth;

  if ((bufferSize mod vectorSize) <> 0) then
  begin
    bufferSize := vectorSize * CeilU(bufferSize / vectorSize);
  end;

  srcBuffer[0] := Context.CreateDeviceBuffer(BufferAccessReadOnly, bufferSize);
  srcBuffer[1] := Context.CreateDeviceBuffer(BufferAccessReadOnly, bufferSize);
  resBuffer[0] := Context.CreateDeviceBuffer(BufferAccessWriteOnly, srcBuffer[0].Size);
  resBuffer[1] := Context.CreateDeviceBuffer(BufferAccessWriteOnly, srcBuffer[1].Size);

  kernelGen := DefaultKernelGenerator(vectorWidth);

  kernelSrc := kernelGen.GenerateDoubleTransformKernel(Expression);

  prog := Context.CreateProgram(kernelSrc);
  if not prog.Build([Device]) then
  begin
    raise Exception.Create('Error building OpenCL kernel:' + #13#10 + prog.BuildLog);
  end;

  kernel := prog.CreateKernel('transform_double');

  workGroupSize := kernel.PreferredWorkgroupSizeMultiple;

  if (workGroupSize = 1) then
    workGroupSize := kernel.MaxWorkgroupSize;

  if (workGroupSize > 1) or (bufferSize < inputSize) then
  begin
    globalWorkSize := workGroupSize * UInt32(Ceil(bufferSize / (SizeOf(double) * workGroupSize)));
  end
  else
  begin
    globalWorkSize := Length(Input);
  end;

  workItemOffset := 0;
  bufferOffset := 0;

  writeEvent[0] := nil;
  writeEvent[1] := nil;
  execEvent[0] := nil;
  execEvent[1] := nil;
  readEvent[0] := nil;
  readEvent[1] := nil;

  current_idx := 1;

  while (bufferOffset < inputSize) do
  begin
    current_idx := (current_idx + 1) and 1;

    bufferRemaining := inputSize - bufferOffset;

    // write doesn't have to wait for the read, only kernel exec using this buffer
    writeEvent[current_idx] := MemWriteQueue.EnqueueWriteBuffer(srcBuffer[current_idx], BufferCommmandNonBlocking, 0, Min(bufferRemaining, srcBuffer[current_idx].Size), @Input[workItemOffset], [execEvent[current_idx]]);

    // update kernel arguments
    kernel.Arguments[0] := srcBuffer[current_idx];
    kernel.Arguments[1] := resBuffer[current_idx];
    kernel.Arguments[2] := UInt64(Length(Input));

    // don't exec kernel until previous write has been done
    execEvent[current_idx] := CmdQueue.Enqueue1DRangeKernel(kernel, Range1D(0), Range1D(globalWorkSize), Range1D(workGroupSize), [writeEvent[current_idx]]);

    readEvent[current_idx] := MemReadQueue.EnqueueReadBuffer(resBuffer[current_idx], BufferCommmandNonBlocking, 0, Min(bufferRemaining, resBuffer[current_idx].Size), @Output[workItemOffset], [execEvent[current_idx]]);

    workItemOffset := workItemOffset + globalWorkSize;
    bufferOffset := workItemOffset * SizeOf(double);
  end;

  // wait for last read
  result := TOpenCLFutureImpl<TArray<double>>.Create(Context, readEvent[current_idx], Output);
end;

function TComputeAlgorithmsOpenCLImpl.TransformPlain(const Input,
  Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>;
var
  vectorWidth, vectorSize: UInt32;
  inputSize, bufferSize: UInt64;
  srcBuffer, resBuffer: CLBuffer;
  prog: CLProgram;
  kernel: CLKernel;
  kernelSrc: string;
  kernelGen: IKernelGenerator;
  workGroupSize: UInt32;
  globalWorkSize: UInt64;
  writeEvent, execEvent, readEvent: CLEvent;
  bufferOffset, bufferRemaining, workItemOffset: UInt64;
begin
  vectorWidth := Max(1, Device.PreferredVectorWidthDouble);
  inputSize := Length(Input) * SizeOf(double);
  bufferSize := Min(DeviceOptimalNonInterleavedBufferSize, inputSize);
  vectorSize := SizeOf(double) * vectorWidth;

  if ((bufferSize mod vectorSize) <> 0) then
  begin
    bufferSize := vectorSize * CeilU(bufferSize / vectorSize);
  end;

  srcBuffer := Context.CreateDeviceBuffer(BufferAccessReadOnly, bufferSize);
  resBuffer := Context.CreateDeviceBuffer(BufferAccessWriteOnly, srcBuffer.Size);

  kernelGen := DefaultKernelGenerator(vectorWidth);

  kernelSrc := kernelGen.GenerateDoubleTransformKernel(Expression);

  prog := Context.CreateProgram(kernelSrc);
  if not prog.Build([Device]) then
  begin
    raise Exception.Create('Error building OpenCL kernel:' + #13#10 + prog.BuildLog);
  end;

  kernel := prog.CreateKernel('transform_double');

  kernel.Arguments[0] := srcBuffer;
  kernel.Arguments[1] := resBuffer;
  kernel.Arguments[2] := UInt64(Length(Input));

  workGroupSize := kernel.PreferredWorkgroupSizeMultiple;

  if (workGroupSize = 1) then
    workGroupSize := kernel.MaxWorkgroupSize;

  if (workGroupSize > 1) or (bufferSize < inputSize) then
  begin
    globalWorkSize := workGroupSize * UInt32(Ceil(bufferSize / (SizeOf(double) * workGroupSize)));
  end
  else
  begin
    globalWorkSize := Length(Input);
  end;

  workItemOffset := 0;
  bufferOffset := 0;

  writeEvent := nil;
  execEvent := nil;
  readEvent := nil;

  while (bufferOffset < inputSize) do
  begin
    bufferRemaining := inputSize - bufferOffset;

    // write doesn't have to wait for the read, only last kernel exec
    writeEvent := MemWriteQueue.EnqueueWriteBuffer(srcBuffer, BufferCommmandNonBlocking, 0, Min(bufferRemaining, srcBuffer.Size), @Input[workItemOffset], [execEvent]);

    // don't exec kernel until previous write has been done
    execEvent := CmdQueue.Enqueue1DRangeKernel(kernel, Range1D(0), Range1D(globalWorkSize), Range1D(workGroupSize), [writeEvent]);

    readEvent := MemReadQueue.EnqueueReadBuffer(resBuffer, BufferCommmandNonBlocking, 0, Min(bufferRemaining, resBuffer.Size), @Output[workItemOffset], [execEvent]);

    workItemOffset := workItemOffset + globalWorkSize;
    bufferOffset := workItemOffset * SizeOf(double);
  end;

  // wait for last read
  result := TOpenCLFutureImpl<TArray<double>>.Create(Context, readEvent, Output);
end;

end.
