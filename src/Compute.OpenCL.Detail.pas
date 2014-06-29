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

  TArrayEnumerator<T> = class(TEnumerator<T>)
  strict private
    FItems: TArray<T>;
    FIndex: integer;
  protected
    function DoGetCurrent: T; override;
    function DoMoveNext: Boolean; override;
  public
    constructor Create(const Items: TArray<T>);
  end;

  TArrayEnumerable<T> = class(TEnumerable<T>)
  private
    FItems: TArray<T>;
  protected
    function DoGetEnumerator: TEnumerator<T>; override;
  public
    constructor Create(const Items: TArray<T>);
  end;

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

  ICLDevice = interface;

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

  ICLDevice = interface
    ['{087B4A38-774B-4DA8-8301-AABF8FF5DBE8}']
    function GetDeviceID: TCLDeviceID;
    function GetName: string;
    function GetIsAvailable: boolean;
    function GetIsType(const DeviceType: TCL_device_type): boolean;

    property DeviceID: TCLDeviceID read GetDeviceID;
    property Name: string read GetName;
    property IsAvailable: boolean read GetIsAvailable;
    property IsType[const DeviceType: TCL_device_type]: boolean read GetIsType;
  end;

  TCLDeviceImpl = class(TCLBaseImpl, ICLDevice)
  strict private
    FDeviceID: TCLDeviceID;
    FName: string;
    FAvailable: TCL_bool;
    FDeviceType: TCL_device_type;

    function GetDeviceInfo<T>(const DeviceInfo: TCL_device_info): T;
    function GetDeviceInfoString(const DeviceInfo: TCL_device_info): string;
  public
    constructor Create(const LogProc: TLogProc; const DeviceID: TCLDeviceID);

    function GetName: string;
    function GetDeviceID: TCLDeviceID;
    function GetIsAvailable: boolean;
    function GetIsType(const DeviceType: TCL_device_type): boolean;
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

{ TArrayEnumerator<T> }

constructor TArrayEnumerator<T>.Create(const Items: TArray<T>);
begin
  inherited Create;

  FItems := Items;
  FIndex := -1;
end;

function TArrayEnumerator<T>.DoGetCurrent: T;
begin
  result := FItems[FIndex];
end;

function TArrayEnumerator<T>.DoMoveNext: Boolean;
begin
  result := (FIndex + 1) >= Length(FItems);
  if not result then
    exit;
  FIndex := FIndex + 1;
end;

{ TArrayEnumerable<T> }

constructor TArrayEnumerable<T>.Create(const Items: TArray<T>);
begin
  inherited Create;
  FItems := Items;
end;

function TArrayEnumerable<T>.DoGetEnumerator: TEnumerator<T>;
begin
  result := TArrayEnumerator<T>.Create(FItems);
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
    InitOpenCL();

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

{ TCLDeviceImpl }

constructor TCLDeviceImpl.Create(const LogProc: TLogProc;
  const DeviceID: TCLDeviceID);
begin
  inherited Create(LogProc);

  FDeviceID := DeviceId;

  FName := GetDeviceInfoString(CL_DEVICE_NAME);
  FDeviceType := GetDeviceInfo<TCL_device_type>(CL_DEVICE_TYPE);
  FAvailable := GetDeviceInfo<TCL_bool>(CL_DEVICE_AVAILABLE);

  Log('  Name: %s', [FName]);
  Log('  Type: %s', [DeviceTypeToStr(FDeviceType)]);
  Log('  Available: %s', [BoolToStr(FAvailable <> 0, True)]);
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

function TCLDeviceImpl.GetIsAvailable: boolean;
begin
  result := FAvailable <> 0;
end;

function TCLDeviceImpl.GetIsType(const DeviceType: TCL_device_type): boolean;
begin
  result := (DeviceType and FDeviceType) <> 0;
end;

function TCLDeviceImpl.GetName: string;
begin
  result := FName;
end;

end.
