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
  Compute.Future;

type
  Expr = Compute.ExprTrees.Expr;

  Buffer = record
  strict private
    FCmdQueue: Compute.OpenCL.CLCommandQueue;
    FBuffer: Compute.OpenCL.CLBuffer;

    function GetSize: UInt64;
  private
    class function Create(const CmdQueue: Compute.OpenCL.CLCommandQueue; const Buf: Compute.OpenCL.CLBuffer): Buffer; static;

    property CmdQueue: Compute.OpenCL.CLCommandQueue read FCmdQueue;
    property Buffer: Compute.OpenCL.CLBuffer read FBuffer;
  public

    function ToArray: TArray<double>;

    property Size: UInt64 read GetSize;
  end;

function Constant(const Value: double): Expr.Constant;
function Variable(const Name: string): Expr.Variable;
function ArrayVariable(const Name: string; const Count: integer): Expr.ArrayVariable;
function Func1(const Name: string; const FuncBody: Expr): Expr.Func1;
function Func2(const Name: string; const FuncBody: Expr): Expr.Func2;
function _1: Expr.LambdaParam;
function _2: Expr.LambdaParam;

procedure InitializeCompute;

function NewBuffer(const Size: UInt64): Buffer; overload;
function NewBuffer(const InitialData: TArray<double>): Buffer; overload;
procedure CopyBuffer(const SourceBuffer, DestBuffer: Buffer);

function AsyncTransform(const InputBuffer: Buffer; const Expression: Expr): Future<Buffer>; overload;
// the output buffer is returned in the future
function AsyncTransform(const InputBuffer, OutputBuffer: Buffer; const Expression: Expr): Future<Buffer>; overload;
function AsyncTransform(const Input: TArray<double>; const Expression: Expr): Future<TArray<double>>; overload;
function Transform(const Input: TArray<double>; const Expression: Expr): TArray<double>;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Math,
  Compute.OpenCL.KernelGenerator, Compute.Future.Detail;

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

{ Buffer }

class function Buffer.Create(const CmdQueue: Compute.OpenCL.CLCommandQueue;
  const Buf: Compute.OpenCL.CLBuffer): Buffer;
begin
  result.FCmdQueue := CmdQueue;
  result.FBuffer := Buf;
end;

function Buffer.GetSize: UInt64;
begin
  result := FBuffer.Size;
end;

function Buffer.ToArray: TArray<double>;
var
  len: UInt64;
begin
  len := FBuffer.Size div SizeOf(double);
  SetLength(result, len);

  FCmdQueue.EnqueueReadBuffer(FBuffer, BufferCommandBlocking, 0, len * SizeOf(double), result, []);
end;


type
  IComputeAlgorithms = interface
    ['{941C09AD-FEEC-4BFE-A9C1-C40A3C0D27C0}']

    procedure Initialize;

    function AllocDeviceBuffer(const Size: UInt64; const InitialData: pointer = nil): Buffer;
    function AllocHostBuffer(const Size: UInt64; const InitialData: pointer = nil): Buffer;

    function Transform(const Input, Result: TArray<double>; const Expression: Expr): Future<TArray<double>>; overload;
    function Transform(const InputBuffer, ResultBuffer: Buffer; const Expression: Expr): Future<Buffer>; overload;
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

    function AllocDeviceBuffer(const Size: UInt64; const InitialData: pointer): Buffer;
    function AllocHostBuffer(const Size: UInt64; const InitialData: pointer): Buffer;

    function TransformPlain(const Input, Output: TArray<double>; const Expression: Expr): Future<TArray<double>>; overload;
    function TransformInterleaved(const Input, Output: TArray<double>; const Expression: Expr): Future<TArray<double>>; overload;

    function Transform(const Input, Output: TArray<double>; const Expression: Expr): Future<TArray<double>>; overload;
    function Transform(const InputBuffer, ResultBuffer: Buffer; const Expression: Expr): Future<Buffer>; overload;

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

function NewBuffer(const Size: UInt64): Buffer;
begin
  result := Algorithms.AllocHostBuffer(Size);
end;

function NewBuffer(const InitialData: TArray<double>): Buffer;
var
  size: UInt64;
begin
  size := SizeOf(double) * Length(InitialData);
  result := Algorithms.AllocHostBuffer(size, InitialData);
end;

procedure CopyBuffer(const SourceBuffer, DestBuffer: Buffer);
var
  event: CLEvent;
begin
  event := DestBuffer.CmdQueue.EnqueueCopyBuffer(
    SourceBuffer.Buffer,
    DestBuffer.Buffer,
    0, 0,
    Min(SourceBuffer.Buffer.Size, DestBuffer.Buffer.Size), []);

  event.Wait;
end;

function AsyncTransform(const InputBuffer: Buffer; const Expression: Expr): Future<Buffer>; overload;
var
  outputBuffer: Buffer;
begin
  outputBuffer := NewBuffer(InputBuffer.Size);

  result := AsyncTransform(InputBuffer, outputBuffer, Expression);
end;

function AsyncTransform(const InputBuffer, OutputBuffer: Buffer; const Expression: Expr): Future<Buffer>; overload;
begin
  result := Algorithms.Transform(InputBuffer, OutputBuffer, Expression);
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

{ TComputeAlgorithmsOpenCLImpl }

function TComputeAlgorithmsOpenCLImpl.AllocDeviceBuffer(
  const Size: UInt64; const InitialData: pointer): Buffer;
var
  buf: CLBuffer;
begin
  buf := Context.CreateDeviceBuffer(BufferAccessReadWrite, Size, InitialData);
  result := Buffer.Create(CmdQueue, buf);
end;

function TComputeAlgorithmsOpenCLImpl.AllocHostBuffer(
  const Size: UInt64; const InitialData: pointer): Buffer;
var
  buf: CLBuffer;
begin
  buf := Context.CreateHostBuffer(BufferAccessReadWrite, Size, InitialData);
  result := Buffer.Create(CmdQueue, buf);
end;

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
  Output: TArray<double>; const Expression: Expr): Future<TArray<double>>;
begin
  if (Length(Input) <> Length(Output)) then
    raise EArgumentException.Create('Transform: Input length is not equal to output length');

  //if (Length(Input) <= 256 * 1024 * 1024) then
  //result := TransformPlain(Input, Output, Expression);
  result := TransformInterleaved(Input, Output, Expression);
end;

function TComputeAlgorithmsOpenCLImpl.Transform(const InputBuffer,
  ResultBuffer: Buffer; const Expression: Expr): Future<Buffer>;
var
  vectorWidth, vectorSize: UInt32;
  inputLength, inputSize: UInt64;
  prog: CLProgram;
  kernel: CLKernel;
  kernelSrc: string;
  kernelGen: IKernelGenerator;
  workGroupSize: UInt32;
  globalWorkSize: UInt64;
  execEvent: CLEvent;
begin
  vectorWidth := Max(1, Device.PreferredVectorWidthDouble);
  inputSize := InputBuffer.Size;
  inputLength := inputSize div SizeOf(double);
  vectorSize := SizeOf(double) * vectorWidth;

  if ((inputSize mod vectorSize) <> 0) then
  begin
    vectorWidth := 1;
  end;

  kernelGen := DefaultKernelGenerator(vectorWidth);

  kernelSrc := kernelGen.GenerateDoubleTransformKernel(Expression);

  WriteLn(kernelSrc);

  prog := Context.CreateProgram(kernelSrc);
  if not prog.Build([Device]) then
  begin
    raise Exception.Create('Error building OpenCL kernel:' + #13#10 + prog.BuildLog);
  end;

  kernel := prog.CreateKernel('transform_double');

  kernel.Arguments[0] := InputBuffer.Buffer;
  kernel.Arguments[1] := ResultBuffer.Buffer;
  kernel.Arguments[2] := inputLength;

  workGroupSize := kernel.PreferredWorkgroupSizeMultiple;

  if (workGroupSize = 1) then
    workGroupSize := kernel.MaxWorkgroupSize;

  if (workGroupSize > 1) then
  begin
    globalWorkSize := workGroupSize * UInt32(Ceil(inputSize / (SizeOf(double) * workGroupSize)));
  end
  else
  begin
    globalWorkSize := inputLength;
  end;

  // don't exec kernel until previous write has been done
  execEvent := CmdQueue.Enqueue1DRangeKernel(kernel, Range1D(0), Range1D(globalWorkSize), Range1D(workGroupSize), []);

  // wait for last read
  result := TOpenCLFutureImpl<Buffer>.Create(Context, execEvent, ResultBuffer);
end;

function TComputeAlgorithmsOpenCLImpl.TransformInterleaved(const Input,
  Output: TArray<double>; const Expression: Expr): Future<TArray<double>>;
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

  WriteLn(kernelSrc);

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
  Output: TArray<double>; const Expression: Expr): Future<TArray<double>>;
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

  WriteLn(kernelSrc);

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
