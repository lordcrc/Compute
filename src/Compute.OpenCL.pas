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

unit Compute.OpenCL;

interface

uses
  System.SysUtils,
  Generics.Collections,
  cl, cl_platform,
  Compute.OpenCL.Detail;

type
  TLogProc = Compute.OpenCL.Detail.TLogProc;

  CLDeviceType = (DeviceTypeCPU, DeviceTypeGPU, DeviceTypeAccelerator, DeviceTypeDefault);

  CLDeviceExecCapability = (ExecKernel, ExecNativeKernel);
  CLDeviceExecCapabilities = set of CLDeviceExecCapability;

  CLDeviceLocalMemType = (LocalMemTypeLocal, LocalMemTypeGlobal);

  CLCommandType = (
    CommandNDRangeKernel, CommandNativeKernel, CommandTask,
    CommandUser, CommandBarrier, CommandMarker,
    CommandReadBuffer, CommandWriteBuffer, CommandCopyBuffer, CommandFillBuffer,
    CommandReadImage, CommandWriteImage, CommandCopyImage, CommandFillImage,
    CommandCopyImageToBuffer, CommandCopyBufferToImage,
    CommandMapBuffer, CommandMapImage, CommandUnmapMemObject,
    CommandReadBufferRect, CommandWriteBufferRect, CommandCopyBufferRect,
    CommandMigrateMemObjects);

  CLCommandExecutionStatus = (ExecutionStatusComplete, ExecutionStatusRunning, ExecutionStatusSubmitted, ExecutionStatusQueued);

  CLProgramBuildStatus = (BuildStatusNone, BuildStatusError, BuildStatusSuccess, BuildStatusInProgress);

  CLBufferAccess = (BufferAccessReadOnly, BufferAccessWriteOnly, BufferAccessReadWrite);
  CLBufferCommandAsync = (BufferCommandBlocking, BufferCommmandNonBlocking);

  CLCommandQueueProperty = (QueuePropertyOutOfOrderExec, QueuePropertyProfiling);
  CLCommandQueueProperties = set of CLCommandQueueProperty;

  CLDevice = record
  strict private
    FDevice: Compute.OpenCL.Detail.ICLDevice;

    function GetName: string;
    function GetIsAvailable: boolean;
    function GetIsType(const DeviceType: CLDeviceType): boolean;
    function GetExtensions: string;
    function GetSupportsFP64: boolean;
    function GetLittleEndian: boolean;
    function GetErrorCorrectionSupport: boolean;
    function GetExecutionCapabilities: CLDeviceExecCapabilities;
    function GetGlobalMemSize: UInt64;
    function GetLocalMemSize: UInt64;
    function GetLocalMemType: CLDeviceLocalMemType;
    function GetMaxClockFrequency: UInt32;
    function GetMaxComputeUnits: UInt32;
    function GetMaxConstantArgs: UInt32;
    function GetMaxConstantBufferSize: UInt64;
    function GetMaxMemAllocSize: UInt64;
    function GetMaxParameterSize: UInt32;
    function GetMaxWorkgroupSize: UInt32;
    function GetMaxWorkitemDimensions: UInt32;
    function GetMaxWorkitemSizes: TArray<NativeUInt>;
    function GetProfilingTimerResolution: UInt32;
    function GetSupportedQueueProperties: CLCommandQueueProperties;
    function GetVersion: string;
    function GetDriverVersion: string;
  private
    property Device: Compute.OpenCL.Detail.ICLDevice read FDevice;
  public
    ///	<summary>
    ///	  <para>
    ///	    Use this to assign nil to the instance. This will release the
    ///	    internal implementation, and associated resources.
    ///	  </para>
    ///	  <para>
    ///	    Other uses are internal only.
    ///	  </para>
    ///	</summary>
    ///	<param name="DeviceImpl">
    ///	  Pass nil.
    ///	</param>
    ///	<returns>
    ///	  A device instance with no associated implementation. Do not use
    ///	  the returned instance.
    ///	</returns>
    class operator Implicit(const DeviceImpl: Compute.OpenCL.Detail.ICLDevice): CLDevice;

    property Name: string read GetName;
    property IsAvailable: boolean read GetIsAvailable;
    property IsType[const DeviceType: CLDeviceType]: boolean read GetIsType;
    property Extensions: string read GetExtensions;
    property SupportsFP64: boolean read GetSupportsFP64;
    property LittleEndian: boolean read GetLittleEndian;
    property ErrorCorrectionSupport: boolean read GetErrorCorrectionSupport;
    property ExecutionCapabilities: CLDeviceExecCapabilities read GetExecutionCapabilities;
    property GlobalMemSize: UInt64 read GetGlobalMemSize;
    property LocalMemSize: UInt64 read GetLocalMemSize;
    property LocalMemType: CLDeviceLocalMemType read GetLocalMemType;
    property MaxClockFrequency: UInt32 read GetMaxClockFrequency;
    property MaxComputeUnits: UInt32 read GetMaxComputeUnits;
    property MaxConstantArgs: UInt32 read GetMaxConstantArgs;
    property MaxConstantBufferSize: UInt64 read GetMaxConstantBufferSize;
    property MaxMemAllocSize: UInt64 read GetMaxMemAllocSize;
    property MaxParameterSize: UInt32 read GetMaxParameterSize;
    property MaxWorkgroupSize: UInt32 read GetMaxWorkgroupSize;
    property MaxWorkitemDimensions: UInt32 read GetMaxWorkitemDimensions;
    property MaxWorkitemSizes: TArray<NativeUInt> read GetMaxWorkitemSizes;
    property ProfilingTimerResolution: UInt32 read GetProfilingTimerResolution;
    property QueueProperties: CLCommandQueueProperties read GetSupportedQueueProperties;
    property Version: string read GetVersion;
    property DriverVersion: string read GetDriverVersion;
  end;

  CLBuffer = record
  strict private
    FBuffer: Compute.OpenCL.Detail.ICLBuffer;

    function GetSize: UInt64;
  private
    property Buffer: Compute.OpenCL.Detail.ICLBuffer read FBuffer;
  public
    ///	<summary>
    ///	  <para>
    ///	    Use this to assign nil to the instance. This will release the
    ///	    internal implementation, and associated resources.
    ///	  </para>
    ///	  <para>
    ///	    Other uses are internal only.
    ///	  </para>
    ///	</summary>
    ///	<param name="BufferImpl">
    ///	  Pass nil.
    ///	</param>
    ///	<returns>
    ///	  A memory buffer instance with no associated implementation. Do not use
    ///	  the returned instance.
    ///	</returns>
    class operator Implicit(const BufferImpl: Compute.OpenCL.Detail.ICLBuffer): CLBuffer;

    property Size: UInt64 read GetSize;
  end;

  CLKernel = record
  strict private
    FKernel: Compute.OpenCL.Detail.ICLKernel;

    function GetArgumentCount: UInt32;
    function GetMaxWorkgroupSize: UInt32;
    function GetPreferredWorkgroupSizeMultiple: UInt32;
  private
    property Kernel: Compute.OpenCL.Detail.ICLKernel read FKernel;
  private
    type
      Argument = record
      private
        type ArgType = (ArgTypeBuffer, ArgTypeInt32, ArgTypeUInt32,
          ArgTypeInt64, ArgTypeUInt64, ArgTypeFloat, ArgTypeDouble);
      strict private
        FType: ArgType;
        FValueBuffer: TCLBufferHandle;
        FValueInt32: Int32;
        FValueUInt32: UInt32;
        FValueInt64: Int64;
        FValueUInt64: UInt64;
        FValueFloat: single;
        FValueDouble: double;
      public
        function ValuePtr: pointer;
        function ValueSize: UInt64;

        class operator Implicit(const Value: CLBuffer): CLKernel.Argument;
        class operator Implicit(const Value: Int32): CLKernel.Argument;
        class operator Implicit(const Value: UInt32): CLKernel.Argument;
        class operator Implicit(const Value: Int64): CLKernel.Argument;
        class operator Implicit(const Value: UInt64): CLKernel.Argument;
        class operator Implicit(const Value: single): CLKernel.Argument;
        class operator Implicit(const Value: double): CLKernel.Argument;
      end;
    procedure SetArgument(const Index: UInt32; const Arg: CLKernel.Argument);
  public
    ///	<summary>
    ///	  <para>
    ///	    Use this to assign nil to the instance. This will release the
    ///	    internal implementation, and associated resources.
    ///	  </para>
    ///	  <para>
    ///	    Other uses are internal only.
    ///	  </para>
    ///	</summary>
    ///	<param name="KernelImpl">
    ///	  Pass nil.
    ///	</param>
    ///	<returns>
    ///	  A kernel instance with no associated implementation. Do not use
    ///	  the returned instance.
    ///	</returns>
    class operator Implicit(const KernelImpl: Compute.OpenCL.Detail.ICLKernel): CLKernel;

    property Arguments[const Index: UInt32]: CLKernel.Argument write SetArgument;
    property ArgumentCount: UInt32 read GetArgumentCount;
    property MaxWorkgroupSize: UInt32 read GetMaxWorkgroupSize;
    property PreferredWorkgroupSizeMultiple: UInt32 read GetPreferredWorkgroupSizeMultiple;
  end;

  CLProgram = record
  strict private
    FProgram: Compute.OpenCL.Detail.ICLProgram;

    function GetBuildLog: string;
  private
    property Prog: Compute.OpenCL.Detail.ICLProgram read FProgram;
  public
    ///	<summary>
    ///	  <para>
    ///	    Use this to assign nil to the instance. This will release the
    ///	    internal implementation, and associated resources.
    ///	  </para>
    ///	  <para>
    ///	    Other uses are internal only.
    ///	  </para>
    ///	</summary>
    ///	<param name="ProgramImpl">
    ///	  Pass nil.
    ///	</param>
    ///	<returns>
    ///	  A program instance with no associated implementation. Do not use
    ///	  the returned instance.
    ///	</returns>
    class operator Implicit(const ProgramImpl: Compute.OpenCL.Detail.ICLProgram): CLProgram;

    function Build(const Devices: array of CLDevice; const Defines: array of string; const Options: string = ''): boolean; overload;
    function Build(const Devices: array of CLDevice; const Options: string = ''): boolean; overload;

    function CreateKernel(const Name: string): CLKernel;

    property BuildLog: string read GetBuildLog;
  end;

  CLEvent = record
  strict private
    FEvent: Compute.OpenCL.Detail.ICLEvent;

    function GetCommandType: CLCommandType;
    function GetCommandExecutionStatus: CLCommandExecutionStatus;
  private
    property Event: Compute.OpenCL.Detail.ICLEvent read FEvent;
  public
    ///	<summary>
    ///	  <para>
    ///	    Use this to assign nil to the instance. This will release the
    ///	    internal implementation, and associated resources.
    ///	  </para>
    ///	  <para>
    ///	    Other uses are internal only.
    ///	  </para>
    ///	</summary>
    ///	<param name="EventImpl">
    ///	  Pass nil.
    ///	</param>
    ///	<returns>
    ///	  An event instance with no associated implementation. Do not use
    ///	  the returned instance.
    ///	</returns>
    class operator Implicit(const EventImpl: Compute.OpenCL.Detail.ICLEvent): CLEvent;

    property CommandType: CLCommandType read GetCommandType;
    property CommandExecutionStatus: CLCommandExecutionStatus read GetCommandExecutionStatus;
  end;

  CLUserEvent = record
  strict private
    FEvent: Compute.OpenCL.Detail.ICLUserEvent;

    function GetCommandType: CLCommandType;
    function GetCommandExecutionStatus: CLCommandExecutionStatus;
  private
    property Event: Compute.OpenCL.Detail.ICLUserEvent read FEvent;
  public
    ///	<summary>
    ///	  <para>
    ///	    Use this to assign nil to the instance. This will release the
    ///	    internal implementation, and associated resources.
    ///	  </para>
    ///	  <para>
    ///	    Other uses are internal only.
    ///	  </para>
    ///	</summary>
    ///	<param name="UserEventImpl">
    ///	  Pass nil.
    ///	</param>
    ///	<returns>
    ///	  A user event instance with no associated implementation. Do not use
    ///	  the returned instance.
    ///	</returns>
    class operator Implicit(const UserEventImpl: Compute.OpenCL.Detail.ICLUserEvent): CLUserEvent;

    class operator Implicit(const UserEvent: CLUserEvent): CLEvent;

    property CLCommandType: CLCommandType read GetCommandType;
    property CLCommandExecutionStatus: CLCommandExecutionStatus read GetCommandExecutionStatus;
  end;

  Range1D = record
  strict private
    FSizes: TSize1D;

    function GetPtr: PSize1D;
    procedure RangeCheck(const Index: UInt32);
    function GetSizes(const Index: UInt32): TSize_t;
    procedure SetSizes(const Index: UInt32; const Value: TSize_t);
  private
    property Ptr: PSize1D read GetPtr;
  public
    class operator Explicit(const Size: UInt64): Range1D;
    class operator Explicit(const Sizes: array of UInt64): Range1D;

    property Sizes[const Index: UInt32]: TSize_t read GetSizes write SetSizes; default;
  end;

  Range2D = record
  strict private
    FSizes: TSize2D;

    function GetPtr: PSize2D;
    procedure RangeCheck(const Index: UInt32);
    function GetSizes(const Index: UInt32): TSize_t;
    procedure SetSizes(const Index: UInt32; const Value: TSize_t);
  private
    property Ptr: PSize2D read GetPtr;
  public
    class operator Explicit(const Sizes: array of UInt64): Range2D;

    property Sizes[const Index: UInt32]: TSize_t read GetSizes write SetSizes; default;
  end;

  Range3D = record
  strict private
    FSizes: TSize3D;

    function GetPtr: PSize3D;
    procedure RangeCheck(const Index: UInt32);
    function GetSizes(const Index: UInt32): TSize_t;
    procedure SetSizes(const Index: UInt32; const Value: TSize_t);
  private
    property Ptr: PSize3D read GetPtr;
  public
    class operator Explicit(const Sizes: array of UInt64): Range3D;

    property Sizes[const Index: UInt32]: TSize_t read GetSizes write SetSizes; default;
  end;

  CLCommandQueue = record
  strict private
    FQueue: Compute.OpenCL.Detail.ICLCommandQueue;

    function GetProperties: CLCommandQueueProperties;
  private
    property Queue: Compute.OpenCL.Detail.ICLCommandQueue read FQueue;
  public
    ///	<summary>
    ///	  <para>
    ///	    Use this to assign nil to the instance. This will release the
    ///	    internal implementation, and associated resources.
    ///	  </para>
    ///	  <para>
    ///	    Other uses are internal only.
    ///	  </para>
    ///	</summary>
    ///	<param name="CommandQueueImpl">
    ///	  Pass nil.
    ///	</param>
    ///	<returns>
    ///	  A command queue instance with no associated implementation. Do not use
    ///	  the returned instance.
    ///	</returns>
    class operator Implicit(const CommandQueueImpl: Compute.OpenCL.Detail.ICLCommandQueue): CLCommandQueue;

    function EnqueueReadBuffer(const SourceBuffer: CLBuffer; const BufferCommandAsync: CLBufferCommandAsync;
      const SourceOffset, NumberOfBytes: TSize_t; const Target: pointer;
      const WaitList: array of CLEvent): CLEvent;

    function EnqueueWriteBuffer(const TargetBuffer: CLBuffer; const BufferCommandAsync: CLBufferCommandAsync;
      const TargetOffset, NumberOfBytes: TSize_t; const Source: pointer;
      const WaitList: array of CLEvent): CLEvent;

    function EnqueueCopyBuffer(const SourceBuffer, TargetBuffer: CLBuffer;
      SourceOffset, TargetOffset, NumberOfBytes: TSize_t;
      const WaitList: array of CLEvent): CLEvent;

    function Enqueue1DRangeKernel(const Kernel: CLKernel;
      const GlobalWorkSize: Range1D;
      const WaitList: array of CLEvent): CLEvent; overload;

    function Enqueue1DRangeKernel(const Kernel: CLKernel;
      const GlobalWorkOffset: Range1D;
      const GlobalWorkSize: Range1D;
      const LocalWorkSize: Range1D;
      const WaitList: array of CLEvent): CLEvent; overload;

    function Enqueue2DRangeKernel(const Kernel: CLKernel;
      const GlobalWorkSize: Range2D;
      const WaitList: array of CLEvent): CLEvent; overload;

    function Enqueue2DRangeKernel(const Kernel: CLKernel;
      const GlobalWorkOffset: Range2D;
      const GlobalWorkSize: Range2D;
      const LocalWorkSize: Range2D;
      const WaitList: array of CLEvent): CLEvent; overload;

    function Enqueue3DRangeKernel(const Kernel: CLKernel;
      const GlobalWorkSize: Range3D;
      const WaitList: array of CLEvent): CLEvent; overload;

    function Enqueue3DRangeKernel(const Kernel: CLKernel;
      const GlobalWorkOffset: Range3D;
      const GlobalWorkSize: Range3D;
      const LocalWorkSize: Range3D;
      const WaitList: array of CLEvent): CLEvent; overload;

    procedure Flush;
    procedure Finish;

    property Properties: CLCommandQueueProperties read GetProperties;
  end;

  CLContext = record
  strict private
    FContext: Compute.OpenCL.Detail.ICLContext;
  private
    property Context: Compute.OpenCL.Detail.ICLContext read FContext;
  public
    ///	<summary>
    ///	  <para>
    ///	    Use this to assign nil to the instance. This will release the
    ///	    internal implementation, and associated resources.
    ///	  </para>
    ///	  <para>
    ///	    Other uses are internal only.
    ///	  </para>
    ///	</summary>
    ///	<param name="ContextImpl">
    ///	  Pass nil.
    ///	</param>
    ///	<returns>
    ///	  A context instance with no associated implementation. Do not use
    ///	  the returned instance.
    ///	</returns>
    class operator Implicit(const ContextImpl: Compute.OpenCL.Detail.ICLContext): CLContext;

    procedure WaitForEvents(const Events: array of CLEvent);

    function CreateProgram(const Source: string): CLProgram;
    function CreateUserEvent(): CLUserEvent;

    // create host buffer backed by user-managed data
    function CreateUserBuffer(const BufferAccess: CLBufferAccess; const BufferStorage: pointer; const Size: UInt64): CLBuffer; overload;
    function CreateUserBuffer<T>(const BufferAccess: CLBufferAccess; const BufferStorage: TArray<T>): CLBuffer; overload;
    // create host buffer backed by memory allocated by opencl implementation
    // if data pointer is not nil, it's initialized by copying from the data pointer
    function CreateHostBuffer(const BufferAccess: CLBufferAccess; const Size: UInt64; const InitialData: pointer = nil): CLBuffer; overload;
    // create device buffer
    // if data pointer is not nil, it's initialized by copying from the data pointer
    function CreateDeviceBuffer(const BufferAccess: CLBufferAccess; const Size: UInt64; const InitialData: pointer = nil): CLBuffer; overload;
    function CreateDeviceBuffer<T>(const BufferAccess: CLBufferAccess; const InitialData: TArray<T>): CLBuffer; overload;

    function CreateCommandQueue(const Device: CLDevice; const Properties: CLCommandQueueProperties = []): CLCommandQueue;
  end;

  CLPlatform = record
  strict private
    type
      TDeviceEnumerator = class(TEnumerator<CLDevice>)
      strict private
        FEnumerator: TEnumerator<Compute.OpenCL.Detail.ICLDevice>;
      protected
        function DoGetCurrent: CLDevice; override;
        function DoMoveNext: Boolean; override;
      public
        constructor Create(const Enumerator: TEnumerator<Compute.OpenCL.Detail.ICLDevice>);
      end;

      TDeviceEnumerable = class(TEnumerable<CLDevice>)
      strict private
        FEnumerable: TEnumerable<Compute.OpenCL.Detail.ICLDevice>;
      protected
        function DoGetEnumerator: TEnumerator<CLDevice>; override;
      public
        constructor Create(const Enumerable: TEnumerable<Compute.OpenCL.Detail.ICLDevice>);
      end;
  strict private
    FPlatform: Compute.OpenCL.Detail.ICLPlatform;

    function GetExtensions: string;
    function GetName: string;
    function GetProfile: string;
    function GetVendor: string;
    function GetVersion: string;

    function DevicesToArray(const Devices: TEnumerable<Compute.OpenCL.Detail.ICLDevice>): TArray<CLDevice>;

    function GetDevices(const DeviceType: CLDeviceType): TArray<CLDevice>;
    function GetAllDevices: TArray<CLDevice>;
  private
  public
    ///	<summary>
    ///	  <para>
    ///	    Use this to assign nil to the instance. This will release the
    ///	    internal implementation, and associated resources.
    ///	  </para>
    ///	  <para>
    ///	    Other uses are internal only.
    ///	  </para>
    ///	</summary>
    ///	<param name="PlatformImpl">
    ///	  Pass nil.
    ///	</param>
    ///	<returns>
    ///	  A device instance with no associated implementation. Do not use
    ///	  the returned instance.
    ///	</returns>
    class operator Implicit(const PlatformImpl: Compute.OpenCL.Detail.ICLPlatform): CLPlatform;

    function CreateContext(const Devices: array of CLDevice): CLContext;

    property Extensions: string read GetExtensions;
    property Name: string read GetName;
    property Profile: string read GetProfile;
    property Vendor: string read GetVendor;
    property Version: string read GetVersion;

    property Devices[const DeviceType: CLDeviceType]: TArray<CLDevice> read GetDevices;
    property AllDevices: TArray<CLDevice> read GetAllDevices;
  end;

  CLPlatforms = record
  strict private
    FPlatforms: Compute.OpenCL.Detail.ICLPlatforms;

    function GetCount: integer;
    function GetPlatform(const Index: integer): CLPlatform;
  public
    class function Create(const LogProc: TLogProc = nil): CLPlatforms; static;

    property Count: integer read GetCount;
    property Platform[const Index: integer]: CLPlatform read GetPlatform; default;
  end;

implementation

const
// CLDeviceType = (DeviceTypeCPU, DeviceTypeGPU, DeviceTypeAccelerator, DeviceTypeDefault);
  DeviceTypeMap: array[CLDeviceType] of TCL_device_type = (
    CL_DEVICE_TYPE_CPU, CL_DEVICE_TYPE_GPU, CL_DEVICE_TYPE_ACCELERATOR, CL_DEVICE_TYPE_DEFAULT);

  BufferAccessMap: array[CLBufferAccess] of TCL_mem_flags = (
    CL_MEM_READ_ONLY, CL_MEM_WRITE_ONLY, CL_MEM_READ_WRITE);

function CLDevicesToDevices(const Devices: array of CLDevice): TArray<Compute.OpenCL.Detail.ICLDevice>;
var
  i: integer;
begin
  SetLength(result, Length(Devices));
  for i := 0 to High(Devices) do
    result[i] := Devices[i].Device;
end;

function CLEventsToEvents(const Events: array of CLEvent): TArray<Compute.OpenCL.Detail.ICLEvent>;
var
  i: integer;
begin
  SetLength(result, Length(Events));
  for i := 0 to High(Events) do
    result[i] := Events[i].Event;
end;

function MapCommandExecutionStatus(const ExecutionStatus: TCL_int): CLCommandExecutionStatus;
begin
  case ExecutionStatus of
    CL_COMPLETE: result := ExecutionStatusComplete;
    CL_RUNNING: result := ExecutionStatusRunning;
    CL_SUBMITTED: result := ExecutionStatusSubmitted;
    CL_QUEUED: result := ExecutionStatusQueued;
  else
    raise ENotSupportedException.Create('Unknown event command type');
  end;
end;

function MapCommandType(const CmdType: TCL_command_type): CLCommandType;
begin
  case CmdType of
    CL_COMMAND_NDRANGE_KERNEL: result := CommandNDRangeKernel;
    CL_COMMAND_TASK: result := CommandTask;
    CL_COMMAND_NATIVE_KERNEL: result := CommandNativeKernel;
    CL_COMMAND_READ_BUFFER: result := CommandReadBuffer;
    CL_COMMAND_WRITE_BUFFER: result := CommandWriteBuffer;
    CL_COMMAND_COPY_BUFFER: result := CommandCopyBuffer;
    CL_COMMAND_READ_IMAGE: result := CommandReadImage;
    CL_COMMAND_WRITE_IMAGE: result := CommandWriteImage;
    CL_COMMAND_COPY_IMAGE: result := CommandCopyImage;
    CL_COMMAND_COPY_IMAGE_TO_BUFFER: result := CommandCopyImageToBuffer;
    CL_COMMAND_COPY_BUFFER_TO_IMAGE: result := CommandCopyBufferToImage;
    CL_COMMAND_MAP_BUFFER: result := CommandMapBuffer;
    CL_COMMAND_MAP_IMAGE: result := CommandMapImage;
    CL_COMMAND_UNMAP_MEM_OBJECT: result := CommandUnmapMemObject;
    CL_COMMAND_MARKER: result := CommandMarker;
//    CL_COMMAND_ACQUIRE_GL_OBJECTS: result := CommandAquireGLObjects;
//    CL_COMMAND_RELEASE_GL_OBJECTS: result := CommandReleaseGLObjects;
    CL_COMMAND_READ_BUFFER_RECT: result := CommandReadBufferRect;
    CL_COMMAND_WRITE_BUFFER_RECT: result := CommandWriteBufferRect;
    CL_COMMAND_COPY_BUFFER_RECT: result := CommandCopyBufferRect;
    CL_COMMAND_USER: result := CommandUser;
    CL_COMMAND_BARRIER: result := CommandBarrier;
    CL_COMMAND_MIGRATE_MEM_OBJECTS: result := CommandMigrateMemObjects;
    CL_COMMAND_FILL_BUFFER: result := CommandFillBuffer;
    CL_COMMAND_FILL_IMAGE: result := CommandFillImage;
  else
    raise ENotSupportedException.Create('Unknown event command type');
  end;
end;

{ CLDevice }

function CLDevice.GetDriverVersion: string;
begin
  result := FDevice.DriverVersion;
end;

function CLDevice.GetErrorCorrectionSupport: boolean;
begin
  result := FDevice.ErrorCorrectionSupport;
end;

function CLDevice.GetExecutionCapabilities: CLDeviceExecCapabilities;
begin
  result := [];
  if (FDevice.ExecutionCapabilities and CL_EXEC_KERNEL) <> 0 then
    result := result + [ExecKernel];
  if (FDevice.ExecutionCapabilities and CL_EXEC_NATIVE_KERNEL) <> 0 then
    result := result + [ExecNativeKernel];
end;

function CLDevice.GetExtensions: string;
begin
  result := FDevice.Extensions;
end;

function CLDevice.GetGlobalMemSize: UInt64;
begin
  result := FDevice.GlobalMemSize;
end;

function CLDevice.GetIsAvailable: boolean;
begin
  result := FDevice.IsAvailable;
end;

function CLDevice.GetIsType(const DeviceType: CLDeviceType): boolean;
begin
  result := FDevice.IsType[DeviceTypeMap[DeviceType]];
end;

function CLDevice.GetLittleEndian: boolean;
begin
  result := FDevice.LittleEndian;
end;

function CLDevice.GetLocalMemSize: UInt64;
begin
  result := FDevice.LocalMemSize;
end;

function CLDevice.GetLocalMemType: CLDeviceLocalMemType;
begin
  case FDevice.LocalMemType of
    CL_LOCAL: result := LocalMemTypeLocal;
    CL_GLOBAL: result := LocalMemTypeGlobal;
  else
    raise Exception.Create('Invalid local memory type');
  end;
end;

function CLDevice.GetMaxClockFrequency: UInt32;
begin
  result := FDevice.MaxClockFrequency;
end;

function CLDevice.GetMaxComputeUnits: UInt32;
begin
  result := FDevice.MaxComputeUnits;
end;

function CLDevice.GetMaxConstantArgs: UInt32;
begin
  result := FDevice.MaxConstantArgs;
end;

function CLDevice.GetMaxConstantBufferSize: UInt64;
begin
  result := FDevice.MaxConstantBufferSize;
end;

function CLDevice.GetMaxMemAllocSize: UInt64;
begin
  result := FDevice.MaxMemAllocSize;
end;

function CLDevice.GetMaxParameterSize: UInt32;
begin
  result := FDevice.MaxParameterSize;
end;

function CLDevice.GetMaxWorkgroupSize: UInt32;
begin
  result := FDevice.MaxWorkgroupSize;
end;

function CLDevice.GetMaxWorkitemDimensions: UInt32;
begin
  result := FDevice.MaxWorkitemDimensions;
end;

function CLDevice.GetMaxWorkitemSizes: TArray<NativeUInt>;
begin
  result := FDevice.MaxWorkitemSizes;
end;

function CLDevice.GetName: string;
begin
  result := FDevice.Name;
end;

function CLDevice.GetProfilingTimerResolution: UInt32;
begin
  result := FDevice.ProfilingTimerResolution;
end;

function CLDevice.GetSupportedQueueProperties: CLCommandQueueProperties;
begin
  result := [];
  if (FDevice.QueueProperties and CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE) <> 0 then
    result := result + [QueuePropertyOutOfOrderExec];
  if (FDevice.QueueProperties and CL_QUEUE_PROFILING_ENABLE) <> 0 then
    result := result + [QueuePropertyProfiling];
end;

function CLDevice.GetSupportsFP64: boolean;
begin
  result := FDevice.SupportsFP64;
end;

function CLDevice.GetVersion: string;
begin
  result := FDevice.Version;
end;

class operator CLDevice.Implicit(
  const DeviceImpl: Compute.OpenCL.Detail.ICLDevice): CLDevice;
begin
  result.FDevice := DeviceImpl;
end;

{ CLProgram }

function CLProgram.Build(const Devices: array of CLDevice;
  const Defines: array of string; const Options: string): boolean;
var
  devs: TArray<Compute.OpenCL.Detail.ICLDevice>;
begin
  devs := CLDevicesToDevices(Devices);

  result := FProgram.Build(devs, Defines, Options);
end;

function CLProgram.Build(const Devices: array of CLDevice;
  const Options: string): boolean;
begin
  result := Build(Devices, [], Options);
end;

function CLProgram.CreateKernel(const Name: string): CLKernel;
begin
  result := TCLKernelImpl.Create(Prog.LogProc, Prog, Name);
end;

function CLProgram.GetBuildLog: string;
begin
  result := Prog.GetBuildLog;
end;

class operator CLProgram.Implicit(
  const ProgramImpl: Compute.OpenCL.Detail.ICLProgram): CLProgram;
begin
  result.FProgram := ProgramImpl;
end;

{ CLEvent }

function CLEvent.GetCommandExecutionStatus: CLCommandExecutionStatus;
begin
  result := MapCommandExecutionStatus(Event.CommandExecutionStatus);
end;

function CLEvent.GetCommandType: CLCommandType;
begin
  result := MapCommandType(FEvent.CommandType);
end;

class operator CLEvent.Implicit(
  const EventImpl: Compute.OpenCL.Detail.ICLEvent): CLEvent;
begin
  result.FEvent := EventImpl;
end;

{ CLUserEvent }

function CLUserEvent.GetCommandExecutionStatus: CLCommandExecutionStatus;
begin
  result := MapCommandExecutionStatus(FEvent.CommandExecutionStatus);
end;

function CLUserEvent.GetCommandType: CLCommandType;
begin
  result := MapCommandType(FEvent.CommandType);
end;

class operator CLUserEvent.Implicit(const UserEvent: CLUserEvent): CLEvent;
begin
  result := UserEvent.Event;
end;

class operator CLUserEvent.Implicit(
  const UserEventImpl: Compute.OpenCL.Detail.ICLUserEvent): CLUserEvent;
begin
  result.FEvent := UserEventImpl;
end;

{ CLBuffer }

function CLBuffer.GetSize: UInt64;
begin
  result := Buffer.Size;
end;

class operator CLBuffer.Implicit(
  const BufferImpl: Compute.OpenCL.Detail.ICLBuffer): CLBuffer;
begin
  result.FBuffer := BufferImpl;
end;

{ CLCommandQueue }

function CLCommandQueue.Enqueue1DRangeKernel(const Kernel: CLKernel;
  const GlobalWorkSize: Range1D; const WaitList: array of CLEvent): CLEvent;
var
  wl: TArray<Compute.OpenCL.Detail.ICLEvent>;
  e: Compute.OpenCL.Detail.ICLEvent;
begin
  wl := CLEventsToEvents(WaitList);

  Queue.Enqueue1DRangeKernel(Kernel.Kernel, nil, GlobalWorkSize.Ptr, nil, wl, e);

  result := e;
end;

function CLCommandQueue.Enqueue1DRangeKernel(const Kernel: CLKernel;
  const GlobalWorkOffset, GlobalWorkSize, LocalWorkSize: Range1D;
  const WaitList: array of CLEvent): CLEvent;
var
  wl: TArray<Compute.OpenCL.Detail.ICLEvent>;
  e: Compute.OpenCL.Detail.ICLEvent;
begin
  wl := CLEventsToEvents(WaitList);

  Queue.Enqueue1DRangeKernel(Kernel.Kernel, GlobalWorkOffset.Ptr, GlobalWorkSize.Ptr, LocalWorkSize.Ptr, wl, e);

  result := e;
end;

function CLCommandQueue.Enqueue2DRangeKernel(const Kernel: CLKernel;
  const GlobalWorkSize: Range2D; const WaitList: array of CLEvent): CLEvent;
var
  wl: TArray<Compute.OpenCL.Detail.ICLEvent>;
  e: Compute.OpenCL.Detail.ICLEvent;
begin
  wl := CLEventsToEvents(WaitList);

  Queue.Enqueue2DRangeKernel(Kernel.Kernel, nil, GlobalWorkSize.Ptr, nil, wl, e);

  result := e;
end;

function CLCommandQueue.Enqueue2DRangeKernel(const Kernel: CLKernel;
  const GlobalWorkOffset, GlobalWorkSize, LocalWorkSize: Range2D;
  const WaitList: array of CLEvent): CLEvent;
var
  wl: TArray<Compute.OpenCL.Detail.ICLEvent>;
  e: Compute.OpenCL.Detail.ICLEvent;
begin
  wl := CLEventsToEvents(WaitList);

  Queue.Enqueue2DRangeKernel(Kernel.Kernel, GlobalWorkOffset.Ptr, GlobalWorkSize.Ptr, LocalWorkSize.Ptr, wl, e);

  result := e;
end;

function CLCommandQueue.Enqueue3DRangeKernel(const Kernel: CLKernel;
  const GlobalWorkSize: Range3D; const WaitList: array of CLEvent): CLEvent;
var
  wl: TArray<Compute.OpenCL.Detail.ICLEvent>;
  e: Compute.OpenCL.Detail.ICLEvent;
begin
  wl := CLEventsToEvents(WaitList);

  Queue.Enqueue3DRangeKernel(Kernel.Kernel, nil, GlobalWorkSize.Ptr, nil, wl, e);

  result := e;
end;

function CLCommandQueue.Enqueue3DRangeKernel(const Kernel: CLKernel;
  const GlobalWorkOffset, GlobalWorkSize, LocalWorkSize: Range3D;
  const WaitList: array of CLEvent): CLEvent;
var
  wl: TArray<Compute.OpenCL.Detail.ICLEvent>;
  e: Compute.OpenCL.Detail.ICLEvent;
begin
  wl := CLEventsToEvents(WaitList);

  Queue.Enqueue3DRangeKernel(Kernel.Kernel, GlobalWorkOffset.Ptr, GlobalWorkSize.Ptr, LocalWorkSize.Ptr, wl, e);

  result := e;
end;

function CLCommandQueue.EnqueueCopyBuffer(const SourceBuffer,
  TargetBuffer: CLBuffer; SourceOffset, TargetOffset, NumberOfBytes: TSize_t;
  const WaitList: array of CLEvent): CLEvent;
var
  wl: TArray<Compute.OpenCL.Detail.ICLEvent>;
  e: Compute.OpenCL.Detail.ICLEvent;
begin
  wl := CLEventsToEvents(WaitList);

  Queue.EnqueueCopyBuffer(SourceBuffer.Buffer, TargetBuffer.Buffer,
    SourceOffset, TargetOffset, NumberOfBytes, wl, e);

  result := e;
end;

function CLCommandQueue.EnqueueReadBuffer(const SourceBuffer: CLBuffer;
  const BufferCommandAsync: CLBufferCommandAsync; const SourceOffset,
  NumberOfBytes: TSize_t; const Target: pointer;
  const WaitList: array of CLEvent): CLEvent;
var
  wl: TArray<Compute.OpenCL.Detail.ICLEvent>;
  e: Compute.OpenCL.Detail.ICLEvent;
begin
  wl := CLEventsToEvents(WaitList);

  Queue.EnqueueReadBuffer(SourceBuffer.Buffer,
    BufferCommandAsync = BufferCommandBlocking,
    SourceOffset, NumberOfBytes, Target, wl, e);

  result := e;
end;

function CLCommandQueue.EnqueueWriteBuffer(const TargetBuffer: CLBuffer;
  const BufferCommandAsync: CLBufferCommandAsync; const TargetOffset,
  NumberOfBytes: TSize_t; const Source: pointer;
  const WaitList: array of CLEvent): CLEvent;
var
  wl: TArray<Compute.OpenCL.Detail.ICLEvent>;
  e: Compute.OpenCL.Detail.ICLEvent;
begin
  wl := CLEventsToEvents(WaitList);

  Queue.EnqueueWriteBuffer(TargetBuffer.Buffer,
    BufferCommandAsync = BufferCommandBlocking,
    TargetOffset, NumberOfBytes, Source, wl, e);

  result := e;
end;

procedure CLCommandQueue.Finish;
begin
  Queue.Finish;
end;

procedure CLCommandQueue.Flush;
begin
  Queue.Flush;
end;

function CLCommandQueue.GetProperties: CLCommandQueueProperties;
begin
  result := [];
  if (Queue.Properties and CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE) <> 0 then
    result := result + [QueuePropertyOutOfOrderExec];
  if (Queue.Properties and CL_QUEUE_PROFILING_ENABLE) <> 0 then
    result := result + [QueuePropertyProfiling];
end;

class operator CLCommandQueue.Implicit(
  const CommandQueueImpl: Compute.OpenCL.Detail.ICLCommandQueue): CLCommandQueue;
begin
  result.FQueue := CommandQueueImpl;
end;

{ CLContext }

function CLContext.CreateCommandQueue(const Device: CLDevice;
  const Properties: CLCommandQueueProperties): CLCommandQueue;
var
  p: TCL_command_queue_properties;
  q: Compute.OpenCL.Detail.ICLCommandQueue;
begin
  p := 0;
  if QueuePropertyOutOfOrderExec in Properties then
    p := p or CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE;
  if QueuePropertyProfiling in Properties then
    p := p or CL_QUEUE_PROFILING_ENABLE;

  q := Compute.OpenCL.Detail.TCLCommandQueueImpl.Create(Context.LogProc, Context, Device.Device, p);
  result := q;
end;

function CLContext.CreateDeviceBuffer(const BufferAccess: CLBufferAccess;
  const Size: UInt64; const InitialData: pointer): CLBuffer;
var
  b: Compute.OpenCL.Detail.ICLBuffer;
  flags: TCL_mem_flags;
begin
  flags := BufferAccessMap[BufferAccess];
  if (InitialData <> nil) then
    flags := flags or CL_MEM_COPY_HOST_PTR;
  b := TCLBufferImpl.Create(Context.LogProc, Context, flags, Size, InitialData);
  result := b;
end;

function CLContext.CreateDeviceBuffer<T>(const BufferAccess: CLBufferAccess;
  const InitialData: TArray<T>): CLBuffer;
begin
  result := CreateDeviceBuffer(BufferAccess,
    Length(InitialData)*SizeOf(T), pointer(InitialData));
end;

function CLContext.CreateHostBuffer(const BufferAccess: CLBufferAccess;
  const Size: UInt64; const InitialData: pointer): CLBuffer;
var
  b: Compute.OpenCL.Detail.ICLBuffer;
  flags: TCL_mem_flags;
begin
  flags := BufferAccessMap[BufferAccess] or CL_MEM_ALLOC_HOST_PTR;
  if (InitialData <> nil) then
    flags := flags or CL_MEM_COPY_HOST_PTR;
  b := TCLBufferImpl.Create(Context.LogProc, Context, flags,
    Size, InitialData);
  result := b;
end;

function CLContext.CreateProgram(const Source: string): CLProgram;
var
  p: Compute.OpenCL.Detail.ICLProgram;
begin
  p := TCLProgramImpl.Create(Context.LogProc, Context, Source);
  result := p;
end;

function CLContext.CreateUserBuffer(const BufferAccess: CLBufferAccess;
  const BufferStorage: pointer; const Size: UInt64): CLBuffer;
var
  b: Compute.OpenCL.Detail.ICLBuffer;
  flags: TCL_mem_flags;
begin
  flags := BufferAccessMap[BufferAccess] or CL_MEM_USE_HOST_PTR;
  b := TCLBufferImpl.Create(Context.LogProc, Context, flags,
    Size, BufferStorage);
  result := b;
end;

function CLContext.CreateUserBuffer<T>(const BufferAccess: CLBufferAccess;
  const BufferStorage: TArray<T>): CLBuffer;
begin
  result := CreateUserBuffer(BufferAccess,
    pointer(BufferStorage), Length(BufferStorage)*SizeOf(T));
end;

function CLContext.CreateUserEvent: CLUserEvent;
var
  e: Compute.OpenCL.Detail.ICLUserEvent;
begin
  e := TCLEventImpl.CreateUser(Context.LogProc, Context);
  result := e;
end;

class operator CLContext.Implicit(
  const ContextImpl: Compute.OpenCL.Detail.ICLContext): CLContext;
begin
  result.FContext := ContextImpl;
end;

procedure CLContext.WaitForEvents(const Events: array of CLEvent);
var
  evts: TArray<Compute.OpenCL.Detail.ICLEvent>;
begin
  evts := CLEventsToEvents(Events);
  Context.WaitForEvents(evts);
end;

{ CLPlatform }

function CLPlatform.CreateContext(const Devices: array of CLDevice): CLContext;
var
  ctx: Compute.OpenCL.Detail.ICLContext;
  props: TArray<TCLContextProperty>;
  devs: TArray<Compute.OpenCL.Detail.ICLDevice>;
begin
  SetLength(props, 1);
  props[0] := TCLContextProperty.Platform(FPlatform.PlatformID);

  devs := CLDevicesToDevices(Devices);

  ctx := Compute.OpenCL.Detail.TCLContextImpl.Create(FPlatform.LogProc, props, devs);
  result := ctx;
end;

function CLPlatform.DevicesToArray(
  const Devices: TEnumerable<Compute.OpenCL.Detail.ICLDevice>): TArray<CLDevice>;
var
  i, len: integer;
  dev: Compute.OpenCL.Detail.ICLDevice;
begin
  len := 8;
  SetLength(result, len);
  i := 0;
  for dev in Devices do
  begin
    if (i > len) then
    begin
      len := len * 2;
      SetLength(result, len);
    end;
    result[i] := dev;
    i := i + 1;
  end;
  SetLength(result, i);
end;

function CLPlatform.GetAllDevices: TArray<CLDevice>;
begin
  result := DevicesToArray(FPlatform.Devices[CL_DEVICE_TYPE_ALL]);
end;

function CLPlatform.GetDevices(
  const DeviceType: CLDeviceType): TArray<CLDevice>;
begin
  result := DevicesToArray(FPlatform.Devices[DeviceTypeMap[DeviceType]]);
end;

function CLPlatform.GetExtensions: string;
begin
  result := FPlatform.Extensions;
end;

function CLPlatform.GetName: string;
begin
  result := FPlatform.Name;
end;

function CLPlatform.GetProfile: string;
begin
  result := FPlatform.Profile;
end;

function CLPlatform.GetVendor: string;
begin
  result := FPlatform.Vendor;
end;

function CLPlatform.GetVersion: string;
begin
  result := FPlatform.Version;
end;

class operator CLPlatform.Implicit(
  const PlatformImpl: Compute.OpenCL.Detail.ICLPlatform): CLPlatform;
begin
  result.FPlatform := PlatformImpl;
end;

{ CLPlatform.TDeviceEnumerator }

constructor CLPlatform.TDeviceEnumerator.Create(
  const Enumerator: TEnumerator<Compute.OpenCL.Detail.ICLDevice>);
begin
  inherited Create;
  FEnumerator := Enumerator;
end;

function CLPlatform.TDeviceEnumerator.DoGetCurrent: CLDevice;
begin
  result := FEnumerator.Current;
end;

function CLPlatform.TDeviceEnumerator.DoMoveNext: Boolean;
begin
  result := FEnumerator.MoveNext;
end;

{ CLPlatform.TDeviceEnumerable }

constructor CLPlatform.TDeviceEnumerable.Create(
  const Enumerable: TEnumerable<Compute.OpenCL.Detail.ICLDevice>);
begin
  inherited Create;
  FEnumerable := Enumerable;
end;

function CLPlatform.TDeviceEnumerable.DoGetEnumerator: TEnumerator<CLDevice>;
begin
  result := CLPlatform.TDeviceEnumerator.Create(FEnumerable.GetEnumerator());
end;

{ CLPlatforms }

class function CLPlatforms.Create(const LogProc: TLogProc): CLPlatforms;
begin
  result.FPlatforms := Compute.OpenCL.Detail.TCLPlatformsImpl.Create(LogProc);
end;

function CLPlatforms.GetCount: integer;
begin
  result := FPlatforms.Count;
end;

function CLPlatforms.GetPlatform(const Index: integer): CLPlatform;
begin
  result := FPlatforms[Index];
end;

{ CLKernel }

function CLKernel.GetArgumentCount: UInt32;
begin
  result := Kernel.ArgumentCount;
end;

function CLKernel.GetMaxWorkgroupSize: UInt32;
begin
  result := Kernel.MaxWorkgroupSize;
end;

function CLKernel.GetPreferredWorkgroupSizeMultiple: UInt32;
begin
  result := Kernel.PreferredWorkgroupSizeMultiple;
end;

class operator CLKernel.Implicit(
  const KernelImpl: Compute.OpenCL.Detail.ICLKernel): CLKernel;
begin
  result.FKernel := KernelImpl;
end;

procedure CLKernel.SetArgument(const Index: UInt32;
  const Arg: CLKernel.Argument);
var
  valuePtr: pointer;
  valueSize: UInt64;
begin
  valuePtr := Arg.ValuePtr;
  valueSize := Arg.ValueSize;

  Kernel.SetArgument(Index, valuePtr, valueSize);
end;

{ CLKernel.Argument }

class operator CLKernel.Argument.Implicit(
  const Value: CLBuffer): CLKernel.Argument;
begin
  result.FType := ArgTypeBuffer;
  result.FValueBuffer := Value.Buffer.Handle;
end;

class operator CLKernel.Argument.Implicit(
  const Value: Int32): CLKernel.Argument;
begin
  result.FType := ArgTypeInt32;
  result.FValueInt32 := Value;
end;

class operator CLKernel.Argument.Implicit(
  const Value: UInt32): CLKernel.Argument;
begin
  result.FType := ArgTypeUInt32;
  result.FValueUInt32 := Value;
end;

class operator CLKernel.Argument.Implicit(
  const Value: single): CLKernel.Argument;
begin
  result.FType := ArgTypeFloat;
  result.FValueFloat := Value;
end;

class operator CLKernel.Argument.Implicit(
  const Value: double): CLKernel.Argument;
begin
  result.FType := ArgTypeDouble;
  result.FValueDouble := Value;
end;

function CLKernel.Argument.ValuePtr: pointer;
begin
  case FType of
    ArgTypeBuffer: result := @FValueBuffer;
    ArgTypeInt32:  result := @FValueInt32;
    ArgTypeUInt32: result := @FValueUInt32;
    ArgTypeInt64:  result := @FValueInt64;
    ArgTypeUInt64: result := @FValueUInt64;
    ArgTypeFloat:  result := @FValueFloat;
    ArgTypeDouble: result := @FValueDouble;
  else
    raise ENotSupportedException.Create('Unknown argument type');
  end;
end;

function CLKernel.Argument.ValueSize: UInt64;
begin
  case FType of
    ArgTypeBuffer: result := SizeOf(TCLBufferHandle);
    ArgTypeInt32:  result := SizeOf(Int32);
    ArgTypeUInt32: result := SizeOf(UInt32);
    ArgTypeInt64:  result := SizeOf(Int64);
    ArgTypeUInt64: result := SizeOf(UInt64);
    ArgTypeFloat:  result := SizeOf(single);
    ArgTypeDouble: result := SizeOf(double);
  else
    raise ENotSupportedException.Create('Unknown argument type');
  end;
end;

class operator CLKernel.Argument.Implicit(
  const Value: Int64): CLKernel.Argument;
begin
  result.FType := ArgTypeInt64;
  result.FValueInt64 := Value;
end;

class operator CLKernel.Argument.Implicit(
  const Value: UInt64): CLKernel.Argument;
begin
  result.FType := ArgTypeUInt64;
  result.FValueUInt64 := Value;
end;

{ Range1D }

class operator Range1D.Explicit(
  const Sizes: array of UInt64): Range1D;
begin
  if (Length(Sizes) > Length(result.FSizes)) then
    raise ERangeError.Create('Invalid range size');

  result.FSizes[0] := Sizes[0];
end;

function Range1D.GetPtr: PSize1D;
begin
  result := @FSizes[0];
end;

function Range1D.GetSizes(const Index: UInt32): TSize_t;
begin
  RangeCheck(Index);

  result := FSizes[Index];
end;

class operator Range1D.Explicit(const Size: UInt64): Range1D;
begin
  result.FSizes[0] := Size;
end;

procedure Range1D.RangeCheck(const Index: UInt32);
begin
  if (Index > High(FSizes)) then
    raise ERangeError.Create('Invalid size index');
end;

procedure Range1D.SetSizes(const Index: UInt32; const Value: TSize_t);
begin
  RangeCheck(Index);

  FSizes[Index] := Value;
end;

{ Range2D }

class operator Range2D.Explicit(
  const Sizes: array of UInt64): Range2D;
begin
  if (Length(Sizes) > Length(result.FSizes)) then
    raise ERangeError.Create('Invalid range size');

  result.FSizes[0] := Sizes[0];
  result.FSizes[1] := Sizes[1];
end;

function Range2D.GetPtr: PSize2D;
begin
  result := @FSizes[0];
end;

function Range2D.GetSizes(const Index: UInt32): TSize_t;
begin
  RangeCheck(Index);

  result := FSizes[Index];
end;

procedure Range2D.RangeCheck(const Index: UInt32);
begin
  if (Index > High(FSizes)) then
    raise ERangeError.Create('Invalid range size index');
end;

procedure Range2D.SetSizes(const Index: UInt32; const Value: TSize_t);
begin
  RangeCheck(Index);

  FSizes[Index] := Value;
end;

{ Range3D }

class operator Range3D.Explicit(
  const Sizes: array of UInt64): Range3D;
begin
  if (Length(Sizes) > Length(result.FSizes)) then
    raise ERangeError.Create('Invalid range size');

  result.FSizes[0] := Sizes[0];
  result.FSizes[1] := Sizes[1];
  result.FSizes[2] := Sizes[2];
end;


function Range3D.GetPtr: PSize3D;
begin
  result := @FSizes[0];
end;

function Range3D.GetSizes(const Index: UInt32): TSize_t;
begin
  RangeCheck(Index);

  result := FSizes[Index];
end;

procedure Range3D.RangeCheck(const Index: UInt32);
begin
  if (Index > High(FSizes)) then
    raise ERangeError.Create('Invalid range size index');
end;

procedure Range3D.SetSizes(const Index: UInt32; const Value: TSize_t);
begin
  RangeCheck(Index);

  FSizes[Index] := Value;
end;

end.
