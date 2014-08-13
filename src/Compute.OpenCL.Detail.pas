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

unit Compute.OpenCL.Detail;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Compute.Common,
  cl, cl_platform;

type
  TLogProc = reference to procedure(const Msg: string);

  TCLPlatformID = PCL_platform_id;
  TCLDeviceID = PCL_device_id;
  TCLContextHandle = PCL_context;
  TCLProgramHandle = PCL_program;
  TCLKernelHandle = PCL_kernel;
  TCLCommandQueueHandle = PCL_command_queue;
  TCLEventHandle = PCL_event;
  TCLBufferHandle = PCL_mem;

  TLoggingObject = class(TInterfacedObject)
  strict private
    FLogProc: TLogProc;
  protected
    procedure Log(const Msg: string); overload;
    procedure Log(const FmtMsg: string; const Args: array of const); overload;

    property LogProc: TLogProc read FLogProc;
  public
    constructor Create(const LogProc: TLogProc);

    function GetLogProc: TLogProc;
    procedure SetLogProc(const Value: TLogProc);
  end;

  ICLBase = interface
    ['{AD9909E5-BFF8-4F21-AA11-AEBD766E70EA}']

    function GetLogProc: TLogProc;
    function GetStatus: TCLStatus;

    procedure SetLogProc(const Value: TLogProc);

    property LogProc: TLogProc read GetLogProc write SetLogProc;
    property Status: TCLStatus read GetStatus;
  end;

  TCLBaseImpl = class(TLoggingObject, ICLBase)
    FStatus: TCLStatus;
    procedure SetStatus(const Value: TCLStatus);
  protected
    property Status: TCLStatus read FStatus write SetStatus;
  public
    constructor Create(const LogProc: TLogProc);

    function GetStatus: TCLStatus;
  end;

  ICLDevice = interface(ICLBase)
    ['{087B4A38-774B-4DA8-8301-AABF8FF5DBE8}']

    function GetDeviceID: TCLDeviceID;
    function GetName: string;
    function GetIsAvailable: boolean;
    function GetIsType(const DeviceType: TCL_device_type): boolean;
    function GetExtensions: string;
    function GetSupportsFP64: boolean;
    function GetLittleEndian: boolean;
    function GetErrorCorrectionSupport: boolean;
    function GetExecutionCapabilities: TCL_device_exec_capabilities;
    function GetGlobalMemSize: UInt64;
    function GetLocalMemSize: UInt64;
    function GetLocalMemType: TCL_device_local_mem_type;
    function GetMaxClockFrequency: UInt32;
    function GetMaxComputeUnits: UInt32;
    function GetMaxConstantArgs: UInt32;
    function GetMaxConstantBufferSize: UInt64;
    function GetMaxMemAllocSize: UInt64;
    function GetMaxParameterSize: NativeUInt;
    function GetMaxWorkgroupSize: NativeUInt;
    function GetMaxWorkitemDimensions: UInt32;
    function GetMaxWorkitemSizes: TArray<NativeUInt>;
    function GetPreferredVectorWidthInt: UInt32;
    function GetPreferredVectorWidthLong: UInt32;
    function GetPreferredVectorWidthFloat: UInt32;
    function GetPreferredVectorWidthDouble: UInt32;
    function GetProfilingTimerResolution: UInt32;
    function GetQueueProperties: TCL_command_queue_properties;
    function GetVersion: string;
    function GetDriverVersion: string;

    property DeviceID: TCLDeviceID read GetDeviceID;
    property Name: string read GetName;
    property IsAvailable: boolean read GetIsAvailable;
    property IsType[const DeviceType: TCL_device_type]: boolean read GetIsType;
    property Extensions: string read GetExtensions;
    property SupportsFP64: boolean read GetSupportsFP64;
    property LittleEndian: boolean read GetLittleEndian;
    property ErrorCorrectionSupport: boolean read GetErrorCorrectionSupport;
    property ExecutionCapabilities: TCL_device_exec_capabilities read GetExecutionCapabilities;
    property GlobalMemSize: UInt64 read GetGlobalMemSize;
    property LocalMemSize: UInt64 read GetLocalMemSize;
    property LocalMemType: TCL_device_local_mem_type read GetLocalMemType;
    property MaxClockFrequency: UInt32 read GetMaxClockFrequency;
    property MaxComputeUnits: UInt32 read GetMaxComputeUnits;
    property MaxConstantArgs: UInt32 read GetMaxConstantArgs;
    property MaxConstantBufferSize: UInt64 read GetMaxConstantBufferSize;
    property MaxMemAllocSize: UInt64 read GetMaxMemAllocSize;
    property MaxParameterSize: NativeUInt read GetMaxParameterSize;
    property MaxWorkgroupSize: NativeUInt read GetMaxWorkgroupSize;
    property MaxWorkitemDimensions: UInt32 read GetMaxWorkitemDimensions;
    property MaxWorkitemSizes: TArray<NativeUInt> read GetMaxWorkitemSizes;
    property PreferredVectorWidthInt: UInt32 read GetPreferredVectorWidthInt;
    property PreferredVectorWidthLong: UInt32 read GetPreferredVectorWidthLong;
    property PreferredVectorWidthFloat: UInt32 read GetPreferredVectorWidthFloat;
    property PreferredVectorWidthDouble: UInt32 read GetPreferredVectorWidthDouble;
    property ProfilingTimerResolution: UInt32 read GetProfilingTimerResolution;
    property QueueProperties: TCL_command_queue_properties read GetQueueProperties;
    property Version: string read GetVersion;
    property DriverVersion: string read GetDriverVersion;
  end;

  TCLDeviceImpl = class(TCLBaseImpl, ICLDevice)
  strict private
    FDeviceID: TCLDeviceID;
    FName: string;
    FAvailable: TCL_bool;
    FDeviceType: TCL_device_type;
    FExtensions: string;
    FLittleEndian: TCL_bool;
    FErrorCorrectionSupport: TCL_bool;
    FExecutionCapabilities: TCL_device_exec_capabilities;
    FGlobalMemSize: TCL_ulong;
    FLocalMemSize: TCL_ulong;
    FLocalMemType: TCL_device_local_mem_type;
    FMaxClockFrequency: TCL_uint;
    FMaxComputeUnits: TCL_uint;
    FMaxConstantArgs: TCL_uint;
    FMaxConstantBufferSize: TCL_ulong;
    FMaxMemAllocSize: TCL_ulong;
    FMaxParameterSize: TSize_t;
    FMaxWorkgroupSize: TSize_t;
    FMaxWorkitemDimensions: TCL_uint;
    FMaxWorkitemSizes: TArray<TSize_t>;
    FPreferredVectorWidthInt: UInt32;
    FPreferredVectorWidthLong: UInt32;
    FPreferredVectorWidthFloat: UInt32;
    FPreferredVectorWidthDouble: UInt32;
    FProfilingTimerResolution: TSize_t;
    FQueueProperties: TCL_command_queue_properties;
    FVersion: string;
    FDriverVersion: string;
    FSupportedExtensions: IDictionary<string,boolean>;

    function GetDeviceInfo<T>(const DeviceInfo: TCL_device_info): T;
    function GetDeviceInfoArray<T>(const DeviceInfo: TCL_device_info; const NumElements: TCL_uint): TArray<T>;
    function GetDeviceInfoString(const DeviceInfo: TCL_device_info): string;
  public
    constructor Create(const LogProc: TLogProc; const DeviceID: TCLDeviceID);

    function GetName: string;
    function GetDeviceID: TCLDeviceID;
    function GetIsAvailable: boolean;
    function GetIsType(const DeviceType: TCL_device_type): boolean;
    function GetExtensions: string;
    function GetSupportsFP64: boolean;
    function GetLittleEndian: boolean;
    function GetErrorCorrectionSupport: boolean;
    function GetExecutionCapabilities: TCL_device_exec_capabilities;
    function GetGlobalMemSize: UInt64;
    function GetLocalMemSize: UInt64;
    function GetLocalMemType: TCL_device_local_mem_type;
    function GetMaxClockFrequency: UInt32;
    function GetMaxComputeUnits: UInt32;
    function GetMaxConstantArgs: UInt32;
    function GetMaxConstantBufferSize: UInt64;
    function GetMaxMemAllocSize: UInt64;
    function GetMaxParameterSize: NativeUInt;
    function GetMaxWorkgroupSize: NativeUInt;
    function GetMaxWorkitemDimensions: UInt32;
    function GetMaxWorkitemSizes: TArray<NativeUInt>;
    function GetPreferredVectorWidthInt: UInt32;
    function GetPreferredVectorWidthLong: UInt32;
    function GetPreferredVectorWidthFloat: UInt32;
    function GetPreferredVectorWidthDouble: UInt32;
    function GetProfilingTimerResolution: UInt32;
    function GetQueueProperties: TCL_command_queue_properties;
    function GetVersion: string;
    function GetDriverVersion: string;
  end;

  ICLPlatform = interface(ICLBase)
    ['{79A90CB4-7717-4352-905D-098A393BB214}']

    function GetExtensions: string;
    function GetName: string;
    function GetProfile: string;
    function GetVendor: string;
    function GetVersion: string;

    function GetDevices(const DeviceType: TCL_device_type): TEnumerable<ICLDevice>;

    function GetPlatformID: TCLPlatformID;

    property PlatformID: TCLPlatformID read GetPlatformID;
    property Extensions: string read GetExtensions;
    property Name: string read GetName;
    property Profile: string read GetProfile;
    property Vendor: string read GetVendor;
    property Version: string read GetVersion;

    property Devices[const DeviceType: TCL_device_type]: TEnumerable<ICLDevice> read GetDevices;
  end;

  TCLPlatformImpl = class(TCLBaseImpl, ICLPlatform)
  strict private
    FPlatformID: TCLPlatformID;
    FExtensions: string;
    FName: string;
    FProfile: string;
    FVendor: string;
    FVersion: string;
    FDevices: IDictionary<TCL_device_type, TArray<ICLDevice>>;

    function GetPlatformInfoString(const PlatformInfo: TCL_platform_info): string;
    procedure GetPlatformDevices;
  public
    constructor Create(const LogProc: TLogProc; const PlatformID: TCLPlatformID);

    function GetPlatformID: TCLPlatformID;
    function GetExtensions: string;
    function GetName: string;
    function GetProfile: string;
    function GetVendor: string;
    function GetVersion: string;
    function GetDevices(const DeviceType: TCL_device_type): TEnumerable<ICLDevice>;
  end;

  ICLPlatforms = interface(ICLBase)
    ['{3D99A624-5057-4B2F-AA27-9FB28A40C1E8}']

    function GetCount: integer;
    function GetCLPlatform(const Index: integer): ICLPlatform;

    property Count: integer read GetCount;
    property CLPlatform[const Index: integer]: ICLPlatform read GetCLPlatform; default;
  end;

  TCLPlatformsImpl = class(TCLBaseImpl, ICLPlatforms)
  strict private
    FPlatformIDs: TArray<TCLPlatformID>;
    FPlatforms: IDictionary<TCLPlatformID, ICLPlatform>;
  public
    constructor Create(const LogProc: TLogProc);

    function GetCount: integer;
    function GetCLPlatform(const Index: integer): ICLPlatform;
  end;

  ICLEvent = interface;

  TCLContextProperty = packed record
    name: PCL_context_properties;
    value: PCL_context_properties;

    class function Terminator: TCLContextProperty; static;
    class function Platform(const Value: TCLPlatformID): TCLContextProperty; static;
  end;

  ICLContext = interface(ICLBase)
    ['{9D8B3AD4-637A-4A3F-B05A-E64E57C5E893}']
    function GetHandle: TCLContextHandle;
    function GetDevices: TArray<ICLDevice>;
    function GetProperties: TArray<TCLContextProperty>;

    procedure WaitForEvents(const Events: array of ICLEvent);

    property Handle: TCLContextHandle read GetHandle;
    property Devices: TArray<ICLDevice> read GetDevices;
    property Properties: TArray<TCLContextProperty> read GetProperties;
  end;

  TCLContextImpl = class(TCLBaseImpl, ICLContext)
  strict private
    FContext: TCLContextHandle;
    FDevices: TArray<ICLDevice>;
    FProperties: TArray<TCLContextProperty>;
  public
    constructor Create(const LogProc: TLogProc; const Properties: TArray<TCLContextProperty>; const Devices: TArray<ICLDevice>);
    destructor Destroy; override;

    function GetHandle: TCLContextHandle;
    function GetDevices: TArray<ICLDevice>;
    function GetProperties: TArray<TCLContextProperty>;

    procedure WaitForEvents(const Events: array of ICLEvent);
  end;

  TCLEventCallback = procedure(const Event: ICLEvent; const CommandExecutionStatus: TCL_int; const UserData: pointer) of object;

  ICLEvent = interface(ICLBase)
    ['{A02E5460-D1A0-4AC8-B07E-DA0E24DF84EA}']

    function GetHandle: TCLEventHandle;
    function GetCommandType: TCL_command_type;
    function GetCommandExecutionStatus: TCL_int;

    procedure SetEventCallback(const CallbackProc: TCLEventCallback; const CommandExecutionStatus: TCL_int; const UserData: pointer);

    procedure Wait;

    property Handle: TCLEventHandle read GetHandle;
    property CommandType: TCL_command_type read GetCommandType;
    property CommandExecutionStatus: TCL_int read GetCommandExecutionStatus;
  end;

  ICLUserEvent = interface(ICLEvent)
    ['{B281D220-B6E5-4C3B-9F74-BA8EEC046655}']

    procedure SetCommandExecutionStatus(const Value: TCL_int);

    property CommandExecutionStatus: TCL_int read GetCommandExecutionStatus write SetCommandExecutionStatus;
  end;

  TCLEventImpl = class(TCLBaseImpl, ICLEvent, ICLUserEvent)
  strict private
    FEvent: TCLEventHandle;
    FCallback: TCLEventCallback;
    FUserData: pointer;

    function GetEventInfo<T>(const EventInfo: TCL_event_info): T;
  public
    constructor Create(const LogProc: TLogProc; const Event: TCLEventHandle);
    constructor CreateUser(const LogProc: TLogProc; const Context: ICLContext);
    destructor Destroy; override;

    procedure DoCallback(const CommandExecutionStatus: TCL_int);

    function GetHandle: TCLEventHandle;
    function GetCommandType: TCL_command_type;
    function GetCommandExecutionStatus: TCL_int;
    procedure SetEventCallback(const CallbackProc: TCLEventCallback; const CommandExecutionStatus: TCL_int; const UserData: pointer);
    procedure SetCommandExecutionStatus(const Value: TCL_int);
    procedure Wait;
  end;

  TCLBinaries = TArray<TBytes>;

  ICLProgram = interface(ICLBase)
    ['{45F39B2D-3295-4FA5-BA0E-388BF36EAC45}']

    function Build(const Devices: TArray<ICLDevice>; const Defines: array of string; const Options: string = ''): boolean;

    function GetBinaries: TCLBinaries;
    function GetBuildLog: string;

    function GetHandle: TCLProgramHandle;
    function GetDevices: TArray<ICLDevice>;

    property Handle: TCLProgramHandle read GetHandle;
    property Devices: TArray<ICLDevice> read GetDevices;
  end;

  TCLProgramImpl = class(TCLBaseImpl, ICLProgram)
  strict private
    FProgram: TCLProgramHandle;
    FDevices: TArray<ICLDevice>;

    function GetProgramBuildInfoString(const Device: ICLDevice; const ProgramBuildInfo: TCL_program_build_info): string;
    function GetProgramBuildInfo<T>(const Device: ICLDevice; const ProgramBuildInfo: TCL_program_build_info): T;
  private
    function Build(const Devices: TArray<ICLDevice>;
      const Defines: array of string; const Options: string): boolean;
  public
    constructor Create(const LogProc: TLogProc; const Context: ICLContext; const Source: string); overload;
    constructor Create(const LogProc: TLogProc; const Context: ICLContext; const Devices: TArray<ICLDevice>; const Binaries: TCLBinaries); overload;
    destructor Destroy; override;

    function GetBinaries: TCLBinaries;
    function GetBuildLog: string;

    function GetHandle: TCLProgramHandle;
    function GetDevices: TArray<ICLDevice>;
  end;

  ICLKernel = interface(ICLBase)
    ['{586955A3-E258-4248-8265-0209018E2F57}']

    function GetHandle: TCLKernelHandle;
    function GetName: string;
    function GetArgumentCount: UInt32;
    function GetMaxWorkgroupSize: UInt32;
    function GetPreferredWorkgroupSizeMultiple: UInt32;
    function GetMaxWorkgroupSizeDevice(const Device: ICLDevice): UInt32;
    function GetPreferredWorkgroupSizeMultipleDevice(const Device: ICLDevice): UInt32;
    function GetPrivateMemorySizeDevice(const Device: ICLDevice): UInt64;

    procedure SetArgument(const Index: TCL_uint; const Value: pointer; const Size: TSize_t);

    property Handle: TCLKernelHandle read GetHandle;
    property Name: string read GetName;
    property ArgumentCount: UInt32 read GetArgumentCount;

    property MaxWorkgroupSize: UInt32 read GetMaxWorkgroupSize;
    property PreferredWorkgroupSizeMultiple: UInt32 read GetPreferredWorkgroupSizeMultiple;
    property MaxWorkgroupSizeDevice[const Device: ICLDevice]: UInt32 read GetMaxWorkgroupSizeDevice;
    property PreferredWorkgroupSizeMultipleDevice[const Device: ICLDevice]: UInt32 read GetPreferredWorkgroupSizeMultipleDevice;
    property PrivateMemorySize[const Device: ICLDevice]: UInt64 read GetPrivateMemorySizeDevice;
  end;

  TCLKernelImpl = class(TCLBaseImpl, ICLKernel)
  strict private
    FKernel: TCLKernelHandle;
    FProg: ICLProgram;
    FName: string;
    FArgCount: TCL_uint;

    function GetKernelInfo<T>(const KernelInfo: TCL_kernel_info): T;
    function GetKernelWorkGroupInfo<T>(const Device: ICLDevice; const KernelWorkGroupInfo: TCL_kernel_work_group_info): T;
  public
    constructor Create(const LogProc: TLogProc; const Prog: ICLProgram; const Name: string);
    destructor Destroy; override;

    function GetHandle: TCLKernelHandle;
    function GetName: string;
    function GetArgumentCount: UInt32;
    function GetMaxWorkgroupSize: UInt32;
    function GetPreferredWorkgroupSizeMultiple: UInt32;
    function GetMaxWorkgroupSizeDevice(const Device: ICLDevice): UInt32;
    function GetPreferredWorkgroupSizeMultipleDevice(const Device: ICLDevice): UInt32;
    function GetPrivateMemorySizeDevice(const Device: ICLDevice): UInt64;

    procedure SetArgument(const Index: TCL_uint; const Value: pointer; const Size: TSize_t);
  end;

  ICLBuffer = interface(ICLBase)
    ['{7F1BE993-D1EF-4DB5-91FF-A8A41CBCD977}']

    function GetHandle: TCLBufferHandle;
    function GetFlags: TCL_mem_flags;
    function GetSize: UInt64;


    property Handle: TCLBufferHandle read GetHandle;
    property Size: UInt64 read GetSize;
    property Flags: TCL_mem_flags read GetFlags;
  end;

  TCLBufferImpl = class(TCLBaseImpl, ICLBuffer)
  strict private
    FBuffer: TCLBufferHandle;
    FFlags: TCL_mem_flags;
    FSize: TSize_t;

    function GetMemObjectInfo<T>(const MemInfo: TCL_mem_info): T;
  public
    constructor Create(const LogProc: TLogProc; const Context: ICLContext;
      const Flags: TCL_mem_flags; const Size: TSize_t; const HostPtr: pointer = nil);
    destructor Destroy; override;

    function GetHandle: TCLBufferHandle;
    function GetFlags: TCL_mem_flags;
    function GetSize: UInt64;
  end;

  TSize1D = packed array[0..0] of TSize_t;
  PSize1D = ^TSize1D;
  TSize2D = packed array[0..1] of TSize_t;
  PSize2D = ^TSize2D;
  TSize3D = packed array[0..2] of TSize_t;
  PSize3D = ^TSize3D;

  ICLCommandQueue = interface(ICLBase)
    ['{9D624027-7F96-45E9-BD3C-7DF4C62BBD44}']

    function GetHandle: TCLCommandQueueHandle;
    function GetProperties: TCL_command_queue_properties;

    procedure EnqueueReadBuffer(const SourceBuffer: ICLBuffer; const Blocking: boolean;
      const SourceOffset, NumberOfBytes: TSize_t; const Target: pointer;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure EnqueueWriteBuffer(const TargetBuffer: ICLBuffer; const Blocking: boolean;
      const TargetOffset, NumberOfBytes: TSize_t; const Source: pointer;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure EnqueueCopyBuffer(const SourceBuffer, TargetBuffer: ICLBuffer;
      SourceOffset, TargetOffset, NumberOfBytes: TSize_t;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure Enqueue1DRangeKernel(const Kernel: ICLKernel;
      const GlobalWorkOffset: PSize1D;
      const GlobalWorkSize: PSize1D;
      const LocalWorkSize: PSize1D;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure Enqueue2DRangeKernel(const Kernel: ICLKernel;
      const GlobalWorkOffset: PSize2D;
      const GlobalWorkSize: PSize2D;
      const LocalWorkSize: PSize2D;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure Enqueue3DRangeKernel(const Kernel: ICLKernel;
      const GlobalWorkOffset: PSize3D;
      const GlobalWorkSize: PSize3D;
      const LocalWorkSize: PSize3D;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure Flush;
    procedure Finish;

    property Handle: TCLCommandQueueHandle read GetHandle;
    property Properties: TCL_command_queue_properties read GetProperties;
  end;

  TCLCommandQueueImpl = class(TCLBaseImpl, ICLCommandQueue)
  strict private
    FQueue: TCLCommandQueueHandle;
    FProperties: TCL_command_queue_properties;
  public
    constructor Create(const LogProc: TLogProc; const Context: ICLContext; const Device: ICLDevice;
      const Properties: TCL_command_queue_properties);
    destructor Destroy; override;

    function GetHandle: TCLCommandQueueHandle;
    function GetProperties: TCL_command_queue_properties;

    procedure EnqueueReadBuffer(const SourceBuffer: ICLBuffer; const Blocking: boolean;
      const SourceOffset, NumberOfBytes: TSize_t; const Target: pointer;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure EnqueueWriteBuffer(const TargetBuffer: ICLBuffer; const Blocking: boolean;
      const TargetOffset, NumberOfBytes: TSize_t; const Source: pointer;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure EnqueueCopyBuffer(const SourceBuffer, TargetBuffer: ICLBuffer;
      SourceOffset, TargetOffset, NumberOfBytes: TSize_t;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure Enqueue1DRangeKernel(const Kernel: ICLKernel;
      const GlobalWorkOffset: PSize1D;
      const GlobalWorkSize: PSize1D;
      const LocalWorkSize: PSize1D;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure Enqueue2DRangeKernel(const Kernel: ICLKernel;
      const GlobalWorkOffset: PSize2D;
      const GlobalWorkSize: PSize2D;
      const LocalWorkSize: PSize2D;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure Enqueue3DRangeKernel(const Kernel: ICLKernel;
      const GlobalWorkOffset: PSize3D;
      const GlobalWorkSize: PSize3D;
      const LocalWorkSize: PSize3D;
      const WaitList: TArray<ICLEvent>; out Event: ICLEvent);

    procedure Flush;
    procedure Finish;
  end;

procedure RaiseCLException(const Status: TCLStatus);

implementation

uses
  System.AnsiStrings, System.Math;

procedure RaiseCLException(const Status: TCLStatus);
begin
  raise ECLException.Create(Status);
end;

const
  BlockingMap: array[boolean] of TCL_uint = (CL_NON_BLOCKING, CL_BLOCKING);

function GetDeviceIDs(const Devices: array of ICLDevice): TArray<TCLDeviceID>;
var
  i: integer;
begin
  SetLength(result, Length(Devices));
  for i := 0 to High(Devices) do
    result[i] := Devices[i].DeviceID;
end;

function DeviceTypeToStr(const DeviceType: TCL_device_type): string;
begin
  result := '';
  if (DeviceType and CL_DEVICE_TYPE_CPU) <> 0 then
    result := result + 'CPU ';
  if (DeviceType and CL_DEVICE_TYPE_GPU) <> 0 then
    result := result + 'GPU ';
  if (DeviceType and CL_DEVICE_TYPE_ACCELERATOR) <> 0 then
    result := result + 'ACCELERATOR ';
  if (DeviceType and CL_DEVICE_TYPE_DEFAULT) <> 0 then
    result := result + 'DEFAULT ';
  result := Trim(result);
end;

function DeviceExecCapabilitiesToStr(const DeviceExecCapabilities: TCL_device_exec_capabilities): string;
begin
  result := '';
  if (DeviceExecCapabilities and CL_EXEC_KERNEL) <> 0 then
    result := result + 'KERNEL ';
  if (DeviceExecCapabilities and CL_EXEC_NATIVE_KERNEL) <> 0 then
    result := result + 'NATIVE ';
  result := Trim(result);
end;

function LocalMemTypeToStr(const LocalMemType: TCL_device_local_mem_type): string;
begin
  case LocalMemType of
    CL_LOCAL: result := 'Local';
    CL_GLOBAL: result := 'Global';
  else
    result := '';
  end;
end;

function GetEventHandles(const Events: array of ICLEvent): TArray<TCLEventHandle>;
var
  i: integer;
begin
  SetLength(result, Length(Events));
  for i := 0 to High(Events) do
    result[i] := Events[i].Handle;
end;

function CommandQueuePropertiesToStr(const CommandQueueProperties: TCL_command_queue_properties): string;
begin
  result := '';
  if (CommandQueueProperties and CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE) <> 0 then
    result := 'OUT-OF-ORDER ';
  if (CommandQueueProperties and CL_QUEUE_PROFILING_ENABLE) <> 0 then
    result := 'PROFILING ';
  result := Trim(result);
end;

function BuildStatusToStr(const BuildStatus: TCL_build_status): string;
begin
  case buildStatus of
    CL_BUILD_NONE: result := 'Not built';
    CL_BUILD_ERROR: result := 'Error';
    CL_BUILD_SUCCESS: result := 'Success';
    CL_BUILD_IN_PROGRESS: result := 'In progress';
  else
    result := 'Unknown build status';
  end;
end;

function UnicodeToLocaleBytes(const s: string; const CodePage: cardinal): TBytes;
var
  rlen: integer;
  usedDefaultChar: LongBool;
begin
  result := nil;
  if (s = '') then
    exit;

  rlen := LocaleCharsFromUnicode(CodePage, 0, PChar(s), Length(s), nil, 0, nil, @usedDefaultChar);
  if (rlen = 0) then
    RaiseLastOSError;

  SetLength(result, rlen+1); // terminator

  if (usedDefaultChar) then
    raise EConvertError.Create('Invalid characters in input');

  rlen := LocaleCharsFromUnicode(CodePage, 0, PChar(s), Length(s), PAnsiChar(result), Length(result), nil, @usedDefaultChar);
  if (rlen = 0) then
    RaiseLastOSError;

  if (usedDefaultChar) then
    raise EConvertError.Create('Invalid characters in input');
end;

function UnicodeToASCIIBytes(const s: string): TBytes;
begin
  result := UnicodeToLocaleBytes(s, TEncoding.ASCII.CodePage);
end;

{ TLoggingObject }

constructor TLoggingObject.Create(const LogProc: TLogProc);
begin
  inherited Create;

  FLogProc := LogProc;
end;

function TLoggingObject.GetLogProc: TLogProc;
begin
  result := FLogProc;
end;

procedure TLoggingObject.Log(const FmtMsg: string; const Args: array of const);
begin
  if not Assigned(FLogProc) then
    exit;

  FLogProc(Format(FmtMsg, Args));
end;

procedure TLoggingObject.Log(const Msg: string);
begin
  if not Assigned(FLogProc) then
    exit;

  FLogProc(Msg);
end;

procedure TLoggingObject.SetLogProc(const Value: TLogProc);
begin
  FLogProc := Value;
end;

{ TCLBaseImpl }

constructor TCLBaseImpl.Create(const LogProc: TLogProc);
begin
  inherited Create(LogProc);
end;

function TCLBaseImpl.GetStatus: TCLStatus;
begin
  result := FStatus;
end;

procedure TCLBaseImpl.SetStatus(const Value: TCLStatus);
begin
  if (Value = FStatus) then
    exit;
  FStatus := Value;
  if (FStatus <> CL_SUCCESS) then
    RaiseCLException(FStatus);
end;

{ TCLDeviceImpl }

constructor TCLDeviceImpl.Create(const LogProc: TLogProc;
  const DeviceID: TCLDeviceID);
var
  wisize: TSize_t;
  s: string;
begin
  inherited Create(LogProc);

  FDeviceID := DeviceId;

  FName := GetDeviceInfoString(CL_DEVICE_NAME);
  FDeviceType := GetDeviceInfo<TCL_device_type>(CL_DEVICE_TYPE);
  FAvailable := GetDeviceInfo<TCL_bool>(CL_DEVICE_AVAILABLE);
  FExtensions := GetDeviceInfoString(CL_DEVICE_EXTENSIONS);
  FVersion := GetDeviceInfoString(CL_DEVICE_VERSION);
  FDriverVersion := GetDeviceInfoString(CL_DRIVER_VERSION);
  FLittleEndian := GetDeviceInfo<TCL_bool>(CL_DEVICE_ENDIAN_LITTLE);
  FErrorCorrectionSupport := GetDeviceInfo<TCL_bool>(CL_DEVICE_ERROR_CORRECTION_SUPPORT);
  FExecutionCapabilities := GetDeviceInfo<TCL_device_exec_capabilities>(CL_DEVICE_EXECUTION_CAPABILITIES);
  FGlobalMemSize := GetDeviceInfo<TCL_ulong>(CL_DEVICE_GLOBAL_MEM_SIZE);
  FLocalMemSize := GetDeviceInfo<TCL_ulong>(CL_DEVICE_LOCAL_MEM_SIZE);
  FLocalMemType := GetDeviceInfo<TCL_device_local_mem_type>(CL_DEVICE_LOCAL_MEM_TYPE);
  FMaxClockFrequency := GetDeviceInfo<TCL_uint>(CL_DEVICE_MAX_CLOCK_FREQUENCY);
  FMaxComputeUnits := GetDeviceInfo<TCL_uint>(CL_DEVICE_MAX_COMPUTE_UNITS);
  FMaxConstantArgs := GetDeviceInfo<TCL_uint>(CL_DEVICE_MAX_CONSTANT_ARGS);
  FMaxConstantBufferSize := GetDeviceInfo<TCL_ulong>(CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE);
  FMaxMemAllocSize := GetDeviceInfo<TCL_ulong>(CL_DEVICE_MAX_MEM_ALLOC_SIZE);
  FMaxParameterSize := GetDeviceInfo<TSize_t>(CL_DEVICE_MAX_PARAMETER_SIZE);
  FMaxWorkgroupSize := GetDeviceInfo<TSize_t>(CL_DEVICE_MAX_WORK_GROUP_SIZE);
  FMaxWorkitemDimensions := GetDeviceInfo<TCL_uint>(CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS);
  FMaxWorkitemSizes := GetDeviceInfoArray<TSize_t>(CL_DEVICE_MAX_WORK_ITEM_SIZES, FMaxWorkitemDimensions);
  FPreferredVectorWidthInt := GetDeviceInfo<TCL_uint>(CL_DEVICE_PREFERRED_VECTOR_WIDTH_INT);
  FPreferredVectorWidthLong := GetDeviceInfo<TCL_uint>(CL_DEVICE_PREFERRED_VECTOR_WIDTH_LONG);
  FPreferredVectorWidthFloat := GetDeviceInfo<TCL_uint>(CL_DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT);
  FPreferredVectorWidthDouble := GetDeviceInfo<TCL_uint>(CL_DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE);
  FProfilingTimerResolution := GetDeviceInfo<TSize_t>(CL_DEVICE_PROFILING_TIMER_RESOLUTION);
  FQueueProperties := GetDeviceInfo<TCL_command_queue_properties>(CL_DEVICE_QUEUE_PROPERTIES);

  FSupportedExtensions := TDictionaryImpl<string, boolean>.Create;
  for s in FExtensions.Split([' '], ExcludeEmpty) do
  begin
    FSupportedExtensions[s] := True;
  end;

  Log('  Name: %s', [FName]);
  Log('  Type: %s', [DeviceTypeToStr(FDeviceType)]);
  Log('  Available: %s', [BoolToStr(FAvailable <> 0, True)]);
  Log('  Extensions: %s', [FExtensions]);
  Log('  Supports FP64: %s', [BoolToStr(GetSupportsFP64(), True)]);
  Log('  OpenCL version: %s', [FVersion]);
  Log('  Driver version: %s', [FDriverVersion]);
  Log('  Little endian: %s', [BoolToStr(FLittleEndian <> 0, True)]);
  Log('  ECC support: %s', [BoolToStr(FErrorCorrectionSupport <> 0, True)]);
  Log('  Execution: %s', [DeviceExecCapabilitiesToStr(FExecutionCapabilities)]);
  Log('  Global memory size: %d', [FGlobalMemSize]);
  Log('  Local memory size: %d', [FLocalMemSize]);
  Log('  Local memory type: %s', [LocalMemTypeToStr(FLocalMemType)]);
  Log('  Max frequency: %d', [FMaxClockFrequency]);
  Log('  Max compute units: %d', [FMaxComputeUnits]);
  Log('  Max constant args: %d', [FMaxConstantArgs]);
  Log('  Max constant buffer size: %d', [FMaxConstantBufferSize]);
  Log('  Max memory allocation size: %d', [FMaxMemAllocSize]);
  Log('  Max parameter size: %d', [FMaxParameterSize]);
  Log('  Max workgroup size: %d', [FMaxWorkgroupSize]);
  Log('  Max workitem dimensions: %d', [FMaxWorkitemDimensions]);

  s := '';
  for wisize in FMaxWorkitemSizes do
  begin
    s := s + ', ' + IntToStr(wisize);
  end;
  Delete(s, 1, 2);
  Log('  Max workitem sizes: (%s)', [s]);

  Log('  Preferred vector width int: %d', [FPreferredVectorWidthInt]);
  Log('  Preferred vector width long: %d', [FPreferredVectorWidthLong]);
  Log('  Preferred vector width float: %d', [FPreferredVectorWidthFloat]);
  Log('  Preferred vector width double: %d', [FPreferredVectorWidthDouble]);
  Log('  Profiling timer resolution: %dns', [FProfilingTimerResolution]);
  Log('  Command queue properties: %s', [CommandQueuePropertiesToStr(FQueueProperties)]);
end;

function TCLDeviceImpl.GetDeviceID: TCLDeviceID;
begin
  result := FDeviceID;
end;

function TCLDeviceImpl.GetDeviceInfo<T>(const DeviceInfo: TCL_device_info): T;
var
  value: T;
  retSize: TSize_t;
begin
  value := Default(T);
  retSize := 0;
  Status := clGetDeviceInfo(FDeviceID, DeviceInfo, SizeOf(T), @value, @retSize);
  if (retSize <> SizeOf(T)) then
    raise Exception.Create('Error while getting device info');
  result := value;
end;

function TCLDeviceImpl.GetDeviceInfoArray<T>(
  const DeviceInfo: TCL_device_info; const NumElements: TCL_uint): TArray<T>;
var
  retSize: TSize_t;
begin
  result := nil;
  SetLength(result, NumElements);
  retSize := 0;
  Status := clGetDeviceInfo(FDeviceID, DeviceInfo, NumElements*SizeOf(T), @result[0], @retSize);
  if (retSize <> (NumElements*SizeOf(T))) then
    raise Exception.Create('Error while getting device info');
end;

function TCLDeviceImpl.GetDeviceInfoString(
  const DeviceInfo: TCL_device_info): string;
var
  size: TSize_t;
  data: TBytes;
begin
  Status := clGetDeviceInfo(FDeviceID, DeviceInfo, 0, nil, @size);
  SetLength(data, size);

  if (size <= 0) then
    exit;

  Status := clGetDeviceInfo(FDeviceID, DeviceInfo, size, data, @size);

  // assume ASCII encoding, specs does not mention encoding at all...
  result := Trim(TEncoding.ASCII.GetString(data));
end;

function TCLDeviceImpl.GetDriverVersion: string;
begin
  result := FDriverVersion;
end;

function TCLDeviceImpl.GetErrorCorrectionSupport: boolean;
begin
  result := FErrorCorrectionSupport <> 0;
end;

function TCLDeviceImpl.GetExecutionCapabilities: TCL_device_exec_capabilities;
begin
  result := FExecutionCapabilities;
end;

function TCLDeviceImpl.GetExtensions: string;
begin
  result := FExtensions;
end;

function TCLDeviceImpl.GetGlobalMemSize: UInt64;
begin
  result := FGlobalMemSize;
end;

function TCLDeviceImpl.GetIsAvailable: boolean;
begin
  result := FAvailable <> 0;
end;

function TCLDeviceImpl.GetIsType(const DeviceType: TCL_device_type): boolean;
begin
  result := (DeviceType and FDeviceType) <> 0;
end;

function TCLDeviceImpl.GetLittleEndian: boolean;
begin
  result := FLittleEndian <> 0;
end;

function TCLDeviceImpl.GetLocalMemSize: UInt64;
begin
  result := FLocalMemSize;
end;

function TCLDeviceImpl.GetLocalMemType: TCL_device_local_mem_type;
begin
  result := FLocalMemType;
end;

function TCLDeviceImpl.GetMaxClockFrequency: UInt32;
begin
  result := FMaxClockFrequency;
end;

function TCLDeviceImpl.GetMaxComputeUnits: UInt32;
begin
  result := FMaxComputeUnits;
end;

function TCLDeviceImpl.GetMaxConstantArgs: UInt32;
begin
  result := FMaxConstantArgs;
end;

function TCLDeviceImpl.GetMaxConstantBufferSize: UInt64;
begin
  result := FMaxConstantBufferSize;
end;

function TCLDeviceImpl.GetMaxMemAllocSize: UInt64;
begin
  result := FMaxMemAllocSize;
end;

function TCLDeviceImpl.GetMaxParameterSize: NativeUInt;
begin
  result := FMaxParameterSize;
end;

function TCLDeviceImpl.GetMaxWorkgroupSize: NativeUInt;
begin
  result := FMaxWorkgroupSize;
end;

function TCLDeviceImpl.GetMaxWorkitemDimensions: UInt32;
begin
  result := FMaxWorkitemDimensions;
end;

function TCLDeviceImpl.GetMaxWorkitemSizes: TArray<NativeUInt>;
begin
  result := FMaxWorkitemSizes;
end;

function TCLDeviceImpl.GetName: string;
begin
  result := FName;
end;

function TCLDeviceImpl.GetPreferredVectorWidthDouble: UInt32;
begin
  result := FPreferredVectorWidthDouble;
end;

function TCLDeviceImpl.GetPreferredVectorWidthFloat: UInt32;
begin
  result := FPreferredVectorWidthFloat;
end;

function TCLDeviceImpl.GetPreferredVectorWidthInt: UInt32;
begin
  result := FPreferredVectorWidthInt;
end;

function TCLDeviceImpl.GetPreferredVectorWidthLong: UInt32;
begin
  result := FPreferredVectorWidthLong;
end;

function TCLDeviceImpl.GetProfilingTimerResolution: UInt32;
begin
  result := FProfilingTimerResolution;
end;

function TCLDeviceImpl.GetQueueProperties: TCL_command_queue_properties;
begin
  result := FQueueProperties;
end;

function TCLDeviceImpl.GetSupportsFP64: boolean;
begin
  result := FSupportedExtensions['cl_khr_fp64'];
end;

function TCLDeviceImpl.GetVersion: string;
begin
  result := FVersion;
end;

{ TCLPlatformImpl }

constructor TCLPlatformImpl.Create(const LogProc: TLogProc; const PlatformID: TCLPlatformID);
begin
  inherited Create(LogProc);

  FPlatformID := PlatformID;

  FProfile := GetPlatformInfoString(CL_PLATFORM_PROFILE);
  FVersion := GetPlatformInfoString(CL_PLATFORM_VERSION);
  FName := GetPlatformInfoString(CL_PLATFORM_NAME);
  FVendor := GetPlatformInfoString(CL_PLATFORM_VENDOR);
  FExtensions := GetPlatformInfoString(CL_PLATFORM_EXTENSIONS);

  Log('  Name: %s', [FName]);
  Log('  Vendor: %s', [FVendor]);
  Log('  Version: %s', [FVersion]);
  Log('  Profile: %s', [FProfile]);
  Log('  Extensions: %s', [FExtensions]);

  FDevices := TDictionaryImpl<TCL_device_type, TArray<ICLDevice>>.Create();

  GetPlatformDevices;
end;

function TCLPlatformImpl.GetDevices(
  const DeviceType: TCL_device_type): TEnumerable<ICLDevice>;
begin
  result := TArrayEnumerable<ICLDevice>.Create(FDevices[DeviceType]);
end;

function TCLPlatformImpl.GetExtensions: string;
begin
  result := FExtensions;
end;

function TCLPlatformImpl.GetName: string;
begin
  result := FName;
end;

procedure TCLPlatformImpl.GetPlatformDevices;
var
  cpuDevices, gpuDevices, accelDevices, defaultDevices, allDevices: IList<ICLDevice>;
  deviceIDs: TArray<TCLDeviceID>;
  numDevices: TCL_uint;
  i: integer;
  device: ICLDevice;
begin
  cpuDevices := TListImpl<ICLDevice>.Create;
  gpuDevices := TListImpl<ICLDevice>.Create;
  accelDevices := TListImpl<ICLDevice>.Create;
  defaultDevices := TListImpl<ICLDevice>.Create;
  allDevices := TListImpl<ICLDevice>.Create;

  Status := clGetDeviceIDs(FPlatformID, CL_DEVICE_TYPE_ALL, 0, nil, @numDevices);
  SetLength(deviceIDs, numDevices);

  Log('Number of devices for platform %s: %d', [FName, numDevices]);

  if (numDevices <= 0) then
    exit;

  Status := clGetDeviceIDs(FPlatformID, CL_DEVICE_TYPE_ALL, Length(deviceIDs), @deviceIDs[0], @numDevices);
  SetLength(deviceIDs, numDevices);

  for i := 0 to High(deviceIDs) do
  begin
    Log('Device #%d details:', [i]);
    device := TCLDeviceImpl.Create(LogProc, deviceIDs[i]);

    allDevices.Add(device);
    if device.IsType[CL_DEVICE_TYPE_DEFAULT] then
      defaultDevices.Add(device);
    if device.IsType[CL_DEVICE_TYPE_CPU] then
      cpuDevices.Add(device);
    if device.IsType[CL_DEVICE_TYPE_GPU] then
      gpuDevices.Add(device);
    if device.IsType[CL_DEVICE_TYPE_ACCELERATOR] then
      accelDevices.Add(device);
  end;

  FDevices[CL_DEVICE_TYPE_DEFAULT] := defaultDevices.ToArray();
  FDevices[CL_DEVICE_TYPE_CPU] := cpuDevices.ToArray();
  FDevices[CL_DEVICE_TYPE_GPU] := gpuDevices.ToArray();
  FDevices[CL_DEVICE_TYPE_ACCELERATOR] := accelDevices.ToArray();
  FDevices[CL_DEVICE_TYPE_ALL] := allDevices.ToArray();
end;

function TCLPlatformImpl.GetPlatformID: TCLPlatformID;
begin
  result := FPlatformID;
end;

function TCLPlatformImpl.GetPlatformInfoString(const PlatformInfo: TCL_platform_info): string;
var
  size: TSize_t;
  data: TBytes;
begin
  Status := clGetPlatformInfo(FPlatformID, PlatformInfo, 0, nil, @size);

  SetLength(data, size);

  Status := clGetPlatformInfo(FPlatformID, PlatformInfo, size, data, @size);

  // assume ASCII encoding, specs does not mention encoding at all...
  result := Trim(TEncoding.ASCII.GetString(data));
end;

function TCLPlatformImpl.GetProfile: string;
begin
  result := FProfile;
end;

function TCLPlatformImpl.GetVendor: string;
begin
  result := FVendor;
end;

function TCLPlatformImpl.GetVersion: string;
begin
  result := FVersion;
end;

{ TPlatformsImpl }

constructor TCLPlatformsImpl.Create(const LogProc: TLogProc);
var
  numPlatforms: TCL_int;
begin
  inherited Create(LogProc);

  if (cl.OCL_LibHandle = nil) then
  begin
    Log('Initializing OpenCL...');
    if not InitOpenCL() then
      raise ECLImplNotFound.Create;
  end;

  numPlatforms := -1;
  Status := clGetPlatformIDs(0, nil, @numPlatforms);
  SetLength(FPlatformIDs, numPlatforms);

  Log('Number of OpenCL platforms: %d', [numPlatforms]);

  Status := clGetPlatformIDs(numPlatforms, @FPlatformIDs[0], @numPlatforms);

  FPlatforms := TDictionaryImpl<TCLPlatformID, ICLPlatform>.Create;
end;

function TCLPlatformsImpl.GetCount: integer;
begin
  result := Length(FPlatformIDs);
end;

function TCLPlatformsImpl.GetCLPlatform(const Index: integer): ICLPlatform;
var
  pid: TCLPlatformID;
begin
  if (Index < 0) or (Index >= Length(FPlatformIDs)) then
    raise ERangeError.Create('GetPlatformID');

  pid := FPlatformIDs[Index];

  result := FPlatforms[pid];
  if Assigned(result) then
    exit;

  Log('Platform #%d details:', [Index]);
  result := TCLPlatformImpl.Create(LogProc, pid);
  FPlatforms[pid] := result;
end;

{ TCLContextProperty }

class function TCLContextProperty.Platform(
  const Value: TCLPlatformID): TCLContextProperty;
begin
  result.name := PCL_context_properties(CL_CONTEXT_PLATFORM);
  result.value := PCL_context_properties(Value);
end;

class function TCLContextProperty.Terminator: TCLContextProperty;
begin
  result.name := PCL_context_properties(0);
  result.value := PCL_context_properties(0);
end;

{ TCLContextImpl }

procedure ContextNotificationCallback(const errinfo: PAnsiChar; const private_info: pointer; cb: TSize_t; user_data: pointer); stdcall;
var
  ctx: TCLContextImpl;
  errorInfo: string;
begin
  errorInfo := string(System.AnsiStrings.StrPas(errinfo));

  ctx := TCLContextImpl(user_data);
  MonitorEnter(ctx);
  try
    ctx.Log(errorInfo);
  finally
    MonitorExit(ctx);
  end;
end;

constructor TCLContextImpl.Create(const LogProc: TLogProc;
  const Properties: TArray<TCLContextProperty>; const Devices: TArray<ICLDevice>);
var
  i: integer;
  props: TArray<TCLContextProperty>;
  devs: TArray<TCLDeviceID>;
  errcode_ret: TCL_int;
begin
  inherited Create(LogProc);

  FProperties := Properties;
  FDevices := Devices;

  props := Copy(Properties);
  i := Length(Properties);
  SetLength(props, i+1);
  props[i] := TCLContextProperty.Terminator;

  devs := GetDeviceIDs(Devices);

  FContext := clCreateContext(@props[0].name, Length(devs), @devs[0], @ContextNotificationCallback, pointer(Self), @errcode_ret);

  Status := errcode_ret;
end;

destructor TCLContextImpl.Destroy;
begin
  if (FContext <> nil) then
    clReleaseContext(FContext);

  inherited;
end;

function TCLContextImpl.GetDevices: TArray<ICLDevice>;
begin
  result := FDevices;
end;

function TCLContextImpl.GetHandle: TCLContextHandle;
begin
  result := FContext;
end;

function TCLContextImpl.GetProperties: TArray<TCLContextProperty>;
begin
  result := FProperties;
end;

procedure TCLContextImpl.WaitForEvents(const Events: array of ICLEvent);
var
  e: TArray<TCLEventHandle>;
begin
  e := GetEventHandles(Events);

  Status := clWaitForEvents(Length(e), PPCL_event(e));
end;

{ TCLEventImpl }

procedure EventCallbackHandler(event: PCL_event; event_command_exec_status: TCL_int; user_data: Pointer); stdcall;
var
  eimpl: TCLEventImpl;
begin
  eimpl := TCLEventImpl(user_data);
  eimpl.DoCallback(event_command_exec_status);
end;

constructor TCLEventImpl.Create(const LogProc: TLogProc; const Event: TCLEventHandle);
begin
  inherited Create(LogProc);

  FEvent := Event;
  // retain event so it doesn't get freed behind our backs
  Status := clRetainEvent(Event);
end;

constructor TCLEventImpl.CreateUser(const LogProc: TLogProc;
  const Context: ICLContext);
var
  errcode_ret: TCL_int;
begin
  inherited Create(LogProc);

  FEvent := clCreateUserEvent(Context.Handle, @errcode_ret);
  Status := errcode_ret;
end;

destructor TCLEventImpl.Destroy;
begin
  if (FEvent <> nil) then
    clReleaseEvent(FEvent);

  inherited;
end;

procedure TCLEventImpl.DoCallback(const CommandExecutionStatus: TCL_int);
begin
  FCallback(Self, CommandExecutionStatus, FUserData);
end;

function TCLEventImpl.GetCommandExecutionStatus: TCL_int;
begin
  result := GetEventInfo<TCL_int>(CL_EVENT_COMMAND_EXECUTION_STATUS);
end;

function TCLEventImpl.GetCommandType: TCL_command_type;
begin
  result := GetEventInfo<TCL_command_type>(CL_EVENT_COMMAND_TYPE);
end;

function TCLEventImpl.GetEventInfo<T>(const EventInfo: TCL_event_info): T;
var
  value: T;
  retSize: TSize_t;
begin
  value := Default(T);
  retSize := 0;
  Status := clGetEventInfo(FEvent, EventInfo, SizeOf(T), @value, @retSize);
  if (retSize <> SizeOf(T)) then
    raise Exception.Create('Error while getting event info');
  result := value;
end;

function TCLEventImpl.GetHandle: TCLEventHandle;
begin
  result := FEvent;
end;

procedure TCLEventImpl.SetCommandExecutionStatus(const Value: TCL_int);
begin
  Status := clSetUserEventStatus(FEvent, Value);
end;

procedure TCLEventImpl.SetEventCallback(const CallbackProc: TCLEventCallback;
  const CommandExecutionStatus: TCL_int; const UserData: pointer);
begin
  raise ENotImplemented.Create('SetEventCallback');

//  if Assigned(FCallback) then
//    raise EInvalidOpException.Create('Only a single callback may be registered on an event');
//
//  FCallback := CallbackProc;
//  FUserData := UserData;
//
//  Status := clSetEventCallback(FEvent, CommandExecutionStatus, @EventCallbackHandler, Self);
end;

procedure TCLEventImpl.Wait;
var
  e: TArray<TCLEventHandle>;
begin
  e := GetEventHandles([Self]);
  Status := clWaitForEvents(1, PPCL_event(e));
end;

{ TCLProgramImpl }

function TCLProgramImpl.Build(const Devices: TArray<ICLDevice>;
  const Defines: array of string; const Options: string): boolean;
var
  i: integer;
  devs: TArray<TCLDeviceID>;
  buildOptions: string;
  opts: TBytes;
  errcode_ret: TCL_int;
begin
  FDevices := Devices;
  devs := GetDeviceIDs(Devices);

  buildOptions := Options;

  for i := 0 to High(Defines) do
    buildOptions := buildOptions + '-D ' + Defines[i];

  opts := UnicodeToASCIIBytes(buildOptions);

  Log('Building program, options: "%s"', [buildOptions]);
  errcode_ret := clBuildProgram(FProgram, Length(devs), @devs[0], PAnsiChar(opts), nil, nil);

  result := (errcode_ret <> CL_INVALID_BINARY) and (errcode_ret <> CL_BUILD_PROGRAM_FAILURE);

  if result then
  begin
    Status := errcode_ret;
  end
  else
  begin
    FStatus := errcode_ret; // don't throw
  end;
end;

constructor TCLProgramImpl.Create(const LogProc: TLogProc;
  const Context: ICLContext; const Source: string);
var
  errcode_ret: TCL_int;
  src: TBytes;
  len: TSize_t;
begin
  inherited Create(LogProc);

  src := UnicodeToASCIIBytes(Source);
  len := Length(src)-1; // exclude null-byte at end

  Log('Program from source');
  FProgram := clCreateProgramWithSource(Context.Handle, 1, PPAnsiChar(@src), @len, @errcode_ret);

  Status := errcode_ret;
end;

constructor TCLProgramImpl.Create(const LogProc: TLogProc;
  const Context: ICLContext; const Devices: TArray<ICLDevice>; const Binaries: TCLBinaries);
var
  errcode_ret: TCL_int;
begin
  inherited Create(LogProc);

  LogProc('Program from binaries');
  raise ENotImplemented.Create('Create Binaries');

  Status := errcode_ret;
end;

destructor TCLProgramImpl.Destroy;
begin
  if (FProgram <> nil) then
    clReleaseProgram(FProgram);

  inherited;
end;

function TCLProgramImpl.GetBinaries: TCLBinaries;
begin
  raise ENotImplemented.Create('GetBinaries');
end;

function TCLProgramImpl.GetBuildLog: string;
var
  i: integer;
  buildStatus: TCL_build_status;
begin
  for i := 0 to High(FDevices) do
  begin
    if (i > 0) then
      result := result + #13#10;

    result := result + 'Device #' + IntToStr(i) + ': ';
    buildStatus := GetProgramBuildInfo<TCL_build_status>(FDevices[i], CL_PROGRAM_BUILD_STATUS);
    result := result + BuildStatusToStr(buildStatus);
    if (buildStatus = CL_BUILD_ERROR) then
    begin
      result := result + #13#10;
      result := result + GetProgramBuildInfoString(FDevices[i], CL_PROGRAM_BUILD_LOG);
    end;
  end;
end;

function TCLProgramImpl.GetDevices: TArray<ICLDevice>;
begin
  result := FDevices;
end;

function TCLProgramImpl.GetHandle: TCLProgramHandle;
begin
  result := FProgram;
end;

function TCLProgramImpl.GetProgramBuildInfo<T>(const Device: ICLDevice;
  const ProgramBuildInfo: TCL_program_build_info): T;
var
  value: T;
  retSize: TSize_t;
begin
  value := Default(T);
  retSize := 0;
  Status := clGetProgramBuildInfo(FProgram, Device.DeviceID, ProgramBuildInfo, SizeOf(T), @value, @retSize);
  if (retSize <> SizeOf(T)) then
    raise Exception.Create('Error while getting program build info');
  result := value;
end;

function TCLProgramImpl.GetProgramBuildInfoString(const Device: ICLDevice;
  const ProgramBuildInfo: TCL_program_build_info): string;
var
  size: TSize_t;
  data: TBytes;
begin
  Status := clGetProgramBuildInfo(FProgram, Device.DeviceID, ProgramBuildInfo, 0, nil, @size);
  SetLength(data, size);

  if (size <= 0) then
    exit;

  Status := clGetProgramBuildInfo(FProgram, Device.DeviceID, ProgramBuildInfo, size, data, @size);

  // assume ASCII encoding, specs does not mention encoding at all...
  result := Trim(TEncoding.ASCII.GetString(data));
end;

{ TCLKernelImpl }

constructor TCLKernelImpl.Create(const LogProc: TLogProc;
  const Prog: ICLProgram; const Name: string);
var
  errcode_ret: TCL_int;
  kernelName: TBytes;
begin
  inherited Create(LogProc);

  FProg := Prog;
  FName := Name;
  kernelName := UnicodeToASCIIBytes(Name);

  Log('Kernel "%s" details:', [Name]);
  FKernel := clCreateKernel(Prog.Handle, PAnsiChar(kernelName), @errcode_ret);
  Status := errcode_ret;

  FArgCount := GetKernelInfo<TCL_uint>(CL_KERNEL_NUM_ARGS);
  Log('  Number of arguments: %d', [FArgCount]);
end;

destructor TCLKernelImpl.Destroy;
begin
  if (FKernel <> nil) then
    clReleaseKernel(FKernel);

  inherited;
end;

function TCLKernelImpl.GetArgumentCount: UInt32;
begin
  result := GetKernelInfo<TCL_uint>(CL_KERNEL_NUM_ARGS);
end;

function TCLKernelImpl.GetHandle: TCLKernelHandle;
begin
  result := FKernel;
end;

function TCLKernelImpl.GetKernelInfo<T>(const KernelInfo: TCL_kernel_info): T;
var
  value: T;
  retSize: TSize_t;
begin
  value := Default(T);
  retSize := 0;
  Status := clGetKernelInfo(FKernel, KernelInfo, SizeOf(T), @value, @retSize);
  if (retSize <> SizeOf(T)) then
    raise Exception.Create('Error while getting kernel info');
  result := value;
end;

function TCLKernelImpl.GetKernelWorkGroupInfo<T>(const Device: ICLDevice;
  const KernelWorkGroupInfo: TCL_kernel_work_group_info): T;
var
  value: T;
  retSize: TSize_t;
begin
  value := Default(T);
  retSize := 0;
  Status := clGetKernelWorkGroupInfo(FKernel, Device.DeviceID, KernelWorkGroupInfo, SizeOf(T), @value, @retSize);
  if (retSize <> SizeOf(T)) then
    raise Exception.Create('Error while getting kernel work-group info');
  result := value;
end;

function TCLKernelImpl.GetMaxWorkgroupSize: UInt32;
var
  dev: ICLDevice;
begin
  result := $ffffffff;
  for dev in FProg.Devices do
  begin
    result := Min(result, GetMaxWorkgroupSizeDevice(dev));
  end;
end;

function TCLKernelImpl.GetMaxWorkgroupSizeDevice(const Device: ICLDevice): UInt32;
begin
  result := GetKernelWorkGroupInfo<TSize_t>(Device, CL_KERNEL_WORK_GROUP_SIZE);
end;

function TCLKernelImpl.GetName: string;
begin
  result := FName;
end;

function TCLKernelImpl.GetPreferredWorkgroupSizeMultiple: UInt32;
var
  dev: ICLDevice;
  md: UInt32;
begin
  result := 1;
  for dev in FProg.Devices do
  begin
    md := GetPreferredWorkgroupSizeMultipleDevice(dev);
    result := LCM(result, md);
  end;
end;

function TCLKernelImpl.GetPreferredWorkgroupSizeMultipleDevice(
  const Device: ICLDevice): UInt32;
begin
  result := GetKernelWorkGroupInfo<TSize_t>(Device, CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE);
end;

function TCLKernelImpl.GetPrivateMemorySizeDevice(const Device: ICLDevice): UInt64;
begin
  result := GetKernelWorkGroupInfo<TCL_ulong>(Device, CL_KERNEL_PRIVATE_MEM_SIZE);
end;

procedure TCLKernelImpl.SetArgument(const Index: TCL_uint; const Value: pointer;
  const Size: TSize_t);
begin
  Status := clSetKernelArg(FKernel, Index, Size, Value);
end;

{ TCLBufferImpl }

constructor TCLBufferImpl.Create(const LogProc: TLogProc;
  const Context: ICLContext;
  const Flags: TCL_mem_flags; const Size: TSize_t; const HostPtr: pointer);
var
  errcode_ret: TCL_int;
begin
  inherited Create(LogProc);

  FBuffer := clCreateBuffer(Context.Handle, Flags, Size, HostPtr, @errcode_ret);
  Status := errcode_ret;

  FFlags := Flags;
  FSize := Size;
end;

destructor TCLBufferImpl.Destroy;
begin
  if (FBuffer <> nil) then
    clReleaseMemObject(FBuffer);

  inherited;
end;

function TCLBufferImpl.GetFlags: TCL_mem_flags;
begin
  result := FFlags;
end;

function TCLBufferImpl.GetHandle: TCLBufferHandle;
begin
  result := FBuffer;
end;

function TCLBufferImpl.GetMemObjectInfo<T>(const MemInfo: TCL_mem_info): T;
var
  value: T;
  retSize: TSize_t;
begin
  value := Default(T);
  retSize := 0;
  Status := clGetMemObjectInfo(FBuffer, MemInfo, SizeOf(T), @value, @retSize);
  if (retSize <> SizeOf(T)) then
    raise Exception.Create('Error while getting buffer info');
  result := value;
end;

function TCLBufferImpl.GetSize: UInt64;
begin
  result := FSize;
end;

{ TCLCommandQueueImpl }

constructor TCLCommandQueueImpl.Create(const LogProc: TLogProc;
  const Context: ICLContext; const Device: ICLDevice;
  const Properties: TCL_command_queue_properties);
var
  errcode_ret: TCL_int;
begin
  inherited Create(LogProc);

  FQueue := clCreateCommandQueue(Context.Handle, Device.DeviceID, Properties, @errcode_ret);
  Status := errcode_ret;

  FProperties := Properties;
end;

destructor TCLCommandQueueImpl.Destroy;
begin
  if (FQueue <> nil) then
    clReleaseCommandQueue(FQueue);

  inherited;
end;

procedure TCLCommandQueueImpl.Enqueue1DRangeKernel(const Kernel: ICLKernel;
  const GlobalWorkOffset, GlobalWorkSize, LocalWorkSize: PSize1D;
  const WaitList: TArray<ICLEvent>; out Event: ICLEvent);
var
  waitEvents: TArray<TCLEventHandle>;
  e: TCLEventHandle;
begin
  waitEvents := GetEventHandles(WaitList);

  Status := clEnqueueNDRangeKernel(FQueue, Kernel.Handle, 1,
    PSize_t(GlobalWorkOffset), PSize_t(GlobalWorkSize), PSize_t(LocalWorkSize),
    Length(waitEvents), PPCL_event(waitEvents), @e);

  Event := TCLEventImpl.Create(LogProc, e);
end;

procedure TCLCommandQueueImpl.Enqueue2DRangeKernel(const Kernel: ICLKernel;
  const GlobalWorkOffset, GlobalWorkSize, LocalWorkSize: PSize2D;
  const WaitList: TArray<ICLEvent>; out Event: ICLEvent);
var
  waitEvents: TArray<TCLEventHandle>;
  e: TCLEventHandle;
begin
  waitEvents := GetEventHandles(WaitList);

  Status := clEnqueueNDRangeKernel(FQueue, Kernel.Handle, 2,
    PSize_t(GlobalWorkOffset), PSize_t(GlobalWorkSize), PSize_t(LocalWorkSize),
    Length(waitEvents), PPCL_event(waitEvents), @e);

  Event := TCLEventImpl.Create(LogProc, e);
end;

procedure TCLCommandQueueImpl.Enqueue3DRangeKernel(const Kernel: ICLKernel;
  const GlobalWorkOffset, GlobalWorkSize, LocalWorkSize: PSize3D;
  const WaitList: TArray<ICLEvent>; out Event: ICLEvent);
var
  waitEvents: TArray<TCLEventHandle>;
  e: TCLEventHandle;
begin
  waitEvents := GetEventHandles(WaitList);

  Status := clEnqueueNDRangeKernel(FQueue, Kernel.Handle, 3,
    PSize_t(GlobalWorkOffset), PSize_t(GlobalWorkSize), PSize_t(LocalWorkSize),
    Length(waitEvents), PPCL_event(waitEvents), @e);

  Event := TCLEventImpl.Create(LogProc, e);
end;

procedure TCLCommandQueueImpl.EnqueueCopyBuffer(const SourceBuffer,
  TargetBuffer: ICLBuffer; SourceOffset, TargetOffset, NumberOfBytes: TSize_t;
  const WaitList: TArray<ICLEvent>; out Event: ICLEvent);
var
  waitEvents: TArray<TCLEventHandle>;
  e: TCLEventHandle;
begin
  waitEvents := GetEventHandles(WaitList);

  Status := clEnqueueCopyBuffer(FQueue, SourceBuffer.Handle, TargetBuffer.Handle,
    SourceOffset, TargetOffset, NumberOfBytes, Length(waitEvents), PPCL_event(waitEvents), @e);

  Event := TCLEventImpl.Create(LogProc, e);
end;

procedure TCLCommandQueueImpl.EnqueueReadBuffer(const SourceBuffer: ICLBuffer;
  const Blocking: boolean; const SourceOffset, NumberOfBytes: TSize_t;
  const Target: pointer; const WaitList: TArray<ICLEvent>; out Event: ICLEvent);
var
  waitEvents: TArray<TCLEventHandle>;
  e: TCLEventHandle;
begin
  waitEvents := GetEventHandles(WaitList);

  Status := clEnqueueReadBuffer(FQueue, SourceBuffer.Handle, BlockingMap[Blocking],
    SourceOffset, NumberOfBytes, Target, Length(waitEvents), PPCL_event(waitEvents), @e);

  Event := TCLEventImpl.Create(LogProc, e);
end;

procedure TCLCommandQueueImpl.EnqueueWriteBuffer(const TargetBuffer: ICLBuffer;
  const Blocking: boolean; const TargetOffset, NumberOfBytes: TSize_t;
  const Source: pointer; const WaitList: TArray<ICLEvent>; out Event: ICLEvent);
var
  waitEvents: TArray<TCLEventHandle>;
  e: TCLEventHandle;
begin
  waitEvents := GetEventHandles(WaitList);

  Status := clEnqueueWriteBuffer(FQueue, TargetBuffer.Handle, BlockingMap[Blocking],
    TargetOffset, NumberOfBytes, Source, Length(waitEvents), PPCL_event(waitEvents), @e);

  Event := TCLEventImpl.Create(LogProc, e);
end;

procedure TCLCommandQueueImpl.Finish;
begin
  Status := clFinish(FQueue);
end;

procedure TCLCommandQueueImpl.Flush;
begin
  Status := clFlush(FQueue);
end;

function TCLCommandQueueImpl.GetHandle: TCLCommandQueueHandle;
begin
  result := FQueue;
end;

function TCLCommandQueueImpl.GetProperties: TCL_command_queue_properties;
begin
  result := FProperties;
end;


end.
