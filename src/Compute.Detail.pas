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

unit Compute.Detail;

interface

uses
  Compute,
  Compute.Common,
  Compute.ExprTrees,
  Compute.OpenCL,
  Compute.Future.Detail;

type
  IComputeAlgorithms = interface
    ['{941C09AD-FEEC-4BFE-A9C1-C40A3C0D27C0}']
    procedure Initialize;

    function Transform(const Input, Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>; overload;
    function Transform(const InputBuffers: array of IFuture<Buffer<double>>; const FirstElement, NumElements: UInt64; const OutputBuffer: Buffer<double>; const Expression: Expr): IFuture<Buffer<double>>; overload;

    function GetContext: CLContext;
    function GetCmdQueue: CLCommandQueue;

    property Context: CLContext read GetContext;
    property CmdQueue: CLCommandQueue read GetCmdQueue;
  end;

function Algorithms: IComputeAlgorithms;

implementation

uses
  System.SysUtils, System.Math,
  Compute.OpenCL.KernelGenerator;

type
  TComputeAlgorithmsOpenCLImpl = class(TInterfacedObject, IComputeAlgorithms)
  strict private
    FDevice: CLDevice;
    FContext: CLContext;
    FCmdQueue: CLCommandQueue;
    FMemReadQueue: CLCommandQueue;
    FMemWriteQueue: CLCommandQueue;

    function DeviceOptimalNonInterleavedBufferSize: UInt64;
    function DeviceOptimalInterleavedBufferSize: UInt64;

    procedure VerifyInputBuffers<T>(const InputBuffers: array of IFuture<Buffer<T>>; const NumElements: UInt64);

    procedure Initialize;

    function TransformPlain(const Input, Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>; overload;
    function TransformInterleaved(const Input, Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>; overload;

    function Transform(const Input, Output: TArray<double>; const Expression: Expr): IFuture<TArray<double>>; overload;

    function Transform(const InputBuffers: array of IFuture<Buffer<double>>; const FirstElement, NumElements: UInt64; const OutputBuffer: Buffer<double>; const Expression: Expr): IFuture<Buffer<double>>; overload;

    function GetContext: CLContext;
    function GetCmdQueue: CLCommandQueue;

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

function TComputeAlgorithmsOpenCLImpl.GetCmdQueue: CLCommandQueue;
begin
  result := FCmdQueue;
end;

function TComputeAlgorithmsOpenCLImpl.GetContext: CLContext;
begin
  result := FContext;
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
  if false and (Length(plat.Devices[DeviceTypeGPU]) > 0) then
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

  WriteLn(kernelSrc);

  prog := Context.CreateProgram(kernelSrc);
  if not prog.Build([Device]) then
  begin
    raise Exception.Create('Error building OpenCL kernel:' + #13#10 + prog.BuildLog);
  end;

  kernel := prog.CreateKernel('transform_double_1');

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
  result := TOpenCLFutureImpl<TArray<double>>.Create(readEvent[current_idx], Output);
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

  WriteLn(kernelSrc);

  prog := Context.CreateProgram(kernelSrc);
  if not prog.Build([Device]) then
  begin
    raise Exception.Create('Error building OpenCL kernel:' + #13#10 + prog.BuildLog);
  end;

  kernel := prog.CreateKernel('transform_double_1');

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
  result := TOpenCLFutureImpl<TArray<double>>.Create(readEvent, Output);
end;

procedure TComputeAlgorithmsOpenCLImpl.VerifyInputBuffers<T>(
  const InputBuffers: array of IFuture<Buffer<T>>;
  const NumElements: UInt64);
var
  numElms: TArray<UInt64>;
  minNum: UInt64;
begin
  numElms := Functional.Map<IFuture<Buffer<T>>, UInt64>(InputBuffers,
    function(const f: IFuture<Buffer<T>>): UInt64
    begin
      result := f.PeekValue.NumElements;
    end);
  minNum := Functional.Reduce<UInt64>(numElms,
    function(const a, b: UInt64): UInt64
    begin
      result := Min(a, b);
    end);

  if (minNum < NumElements) then
    raise EArgumentException.Create('At least one input buffer contains less than the requested number of elements');
end;

function TComputeAlgorithmsOpenCLImpl.Transform(
  const InputBuffers: array of IFuture<Buffer<double>>;
  const FirstElement, NumElements: UInt64;
  const OutputBuffer: Buffer<double>; const Expression: Expr): IFuture<Buffer<double>>;
var
  numInputs: UInt32;
  vectorWidth, vectorSize: UInt32;
  inputLength, inputSize: UInt64;
  prog: CLProgram;
  kernel: CLKernel;
  kernelSrc: string;
  kernelGen: IKernelGenerator;
  workGroupSize: UInt32;
  globalWorkSize: UInt64;
  inputEvents: TArray<CLEvent>;
  execEvent: CLEvent;
  i: UInt32;
begin
  numInputs := Length(InputBuffers);
  vectorWidth := Max(1, Device.PreferredVectorWidthDouble);
  inputSize := NumElements * SizeOf(double);
  inputLength := NumElements;
  vectorSize := SizeOf(double) * vectorWidth;

  VerifyInputBuffers<double>(InputBuffers, NumElements);

  if ((inputSize mod vectorSize) <> 0) then
  begin
    vectorWidth := 1;
  end;

  kernelGen := DefaultKernelGenerator(vectorWidth);

  kernelSrc := kernelGen.GenerateDoubleTransformKernel(Expression, numInputs);

  WriteLn(kernelSrc);

  prog := Context.CreateProgram(kernelSrc);
  if not prog.Build([Device]) then
  begin
    raise Exception.Create('Error building OpenCL kernel:' + #13#10 + prog.BuildLog);
  end;

  kernel := prog.CreateKernel('transform_double_' + IntToStr(numInputs));

  for i := 0 to numInputs-1 do
  begin
    kernel.Arguments[i] := InputBuffers[i].PeekValue.Handle;
  end;
  kernel.Arguments[numInputs+0] := OutputBuffer.Handle;
  kernel.Arguments[numInputs+1] := inputLength;

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

  SetLength(inputEvents, numInputs);
  for i := 0 to numInputs-1 do
    inputEvents[i] := InputBuffers[i].Event;

  // don't exec kernel until buffer is ready
  execEvent := CmdQueue.Enqueue1DRangeKernel(kernel, Range1D(0), Range1D(globalWorkSize), Range1D(workGroupSize), inputEvents);

  // wait for last read
  result := TOpenCLFutureImpl<Buffer<double>>.Create(execEvent, OutputBuffer);
end;

end.
