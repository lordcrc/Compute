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

  ICLDevice = interface
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
    function GetMaxParameterSize: UInt32;
    function GetMaxWorkgroupSize: UInt32;
    function GetMaxWorkitemDimensions: UInt32;
    function GetMaxWorkitemSizes: TArray<UInt32>;
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
    property MaxParameterSize: UInt32 read GetMaxParameterSize;
    property MaxWorkgroupSize: UInt32 read GetMaxWorkgroupSize;
    property MaxWorkitemDimensions: UInt32 read GetMaxWorkitemDimensions;
    property MaxWorkitemSizes: TArray<UInt32> read GetMaxWorkitemSizes;
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
    function GetMaxParameterSize: UInt32;
    function GetMaxWorkgroupSize: UInt32;
    function GetMaxWorkitemDimensions: UInt32;
    function GetMaxWorkitemSizes: TArray<UInt32>;
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

    function GetExtensions: string;
    function GetName: string;
    function GetProfile: string;
    function GetVendor: string;
    function GetVersion: string;
    function GetDevices(const DeviceType: TCL_device_type): TEnumerable<ICLDevice>;
  end;

  ICLPlatforms = interface(ICLBase)
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

procedure RaiseCLException(const Status: TCLStatus);

implementation

procedure RaiseCLException(const Status: TCLStatus);
begin
  raise ECLException.Create(Status);
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

function CommandQueuePropertiesToStr(const CommandQueueProperties: TCL_command_queue_properties): string;
begin
  result := '';
  if (CommandQueueProperties and CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE) <> 0 then
    result := 'OUT-OF-ORDER ';
  if (CommandQueueProperties and CL_QUEUE_PROFILING_ENABLE) <> 0 then
    result := 'PROFILING ';
  result := Trim(result);
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
  if Assigned(FLogProc) then
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

function TCLDeviceImpl.GetMaxParameterSize: UInt32;
begin
  result := FMaxParameterSize;
end;

function TCLDeviceImpl.GetMaxWorkgroupSize: UInt32;
begin
  result := FMaxWorkgroupSize;
end;

function TCLDeviceImpl.GetMaxWorkitemDimensions: UInt32;
begin
  result := FMaxWorkitemDimensions;
end;

function TCLDeviceImpl.GetMaxWorkitemSizes: TArray<UInt32>;
begin
  result := FMaxWorkitemSizes;
end;

function TCLDeviceImpl.GetName: string;
begin
  result := FName;
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
    InitOpenCL();
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

end.
