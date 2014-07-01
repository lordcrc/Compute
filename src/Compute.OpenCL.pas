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
//  TCLPlatformID = Compute.OpenCL.Detail.TCLPlatformID;
//  TCLDeviceID = Compute.OpenCL.Detail.TCLDeviceID;
  TLogProc = Compute.OpenCL.Detail.TLogProc;

  CLDeviceType = (dtCpu, dtGpu, dtAccelerator, dtDefault);

  CLDeviceExecCapability = (ecKernel, ecNativeKernel);
  CLDeviceExecCapabilities = set of CLDeviceExecCapability;

  CLDeviceLocalMemType = (lmLocal, lmGlobal);

  CLCommandQueueProperty = (qpOutOfOrderExec, qpProfiling);
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
    function GetMaxWorkitemSizes: TArray<UInt32>;
    function GetProfilingTimerResolution: UInt32;
    function GetQueueProperties: CLCommandQueueProperties;
    function GetVersion: string;
    function GetDriverVersion: string;
  private
    class function Create(const d: Compute.OpenCL.Detail.ICLDevice): CLDevice; static;
  public
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
    property MaxWorkitemSizes: TArray<UInt32> read GetMaxWorkitemSizes;
    property ProfilingTimerResolution: UInt32 read GetProfilingTimerResolution;
    property QueueProperties: CLCommandQueueProperties read GetQueueProperties;
    property Version: string read GetVersion;
    property DriverVersion: string read GetDriverVersion;
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

    function GetDevices(const DeviceType: CLDeviceType): TEnumerable<CLDevice>;
    function GetAllDevices: TEnumerable<CLDevice>;
  private
    class function Create(const p: Compute.OpenCL.Detail.ICLPlatform): CLPlatform; static;
  public
    property Extensions: string read GetExtensions;
    property Name: string read GetName;
    property Profile: string read GetProfile;
    property Vendor: string read GetVendor;
    property Version: string read GetVersion;

    property Devices[const DeviceType: CLDeviceType]: TEnumerable<CLDevice> read GetDevices;
    property AllDevices: TEnumerable<CLDevice> read GetAllDevices;
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
// CLDeviceType = (dtCpu, dtGpu, dtAccelerator, dtDefault);
  DeviceTypeMap: array[CLDeviceType] of TCL_device_type = (
    CL_DEVICE_TYPE_CPU, CL_DEVICE_TYPE_GPU, CL_DEVICE_TYPE_ACCELERATOR, CL_DEVICE_TYPE_DEFAULT);

{ CLDevice }

class function CLDevice.Create(
  const d: Compute.OpenCL.Detail.ICLDevice): CLDevice;
begin
  result.FDevice := d;
end;

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
    result := result + [ecKernel];
  if (FDevice.ExecutionCapabilities and CL_EXEC_NATIVE_KERNEL) <> 0 then
    result := result + [ecNativeKernel];
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
    CL_LOCAL: result := lmLocal;
    CL_GLOBAL: result := lmGlobal;
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

function CLDevice.GetMaxWorkitemSizes: TArray<UInt32>;
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

function CLDevice.GetQueueProperties: CLCommandQueueProperties;
begin
  result := [];
  if (FDevice.QueueProperties and CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE) <> 0 then
    result := result + [qpOutOfOrderExec];
  if (FDevice.QueueProperties and CL_QUEUE_PROFILING_ENABLE) <> 0 then
    result := result + [qpProfiling];
end;

function CLDevice.GetSupportsFP64: boolean;
begin
  result := FDevice.SupportsFP64;
end;

function CLDevice.GetVersion: string;
begin
  result := FDevice.Version;
end;

{ CLPlatform }

class function CLPlatform.Create(
  const p: Compute.OpenCL.Detail.ICLPlatform): CLPlatform;
begin
  result.FPlatform := p;
end;

function CLPlatform.GetAllDevices: TEnumerable<CLDevice>;
begin
  result := TDeviceEnumerable.Create(FPlatform.Devices[CL_DEVICE_TYPE_ALL]);
end;

function CLPlatform.GetDevices(
  const DeviceType: CLDeviceType): TEnumerable<CLDevice>;
begin
  result := TDeviceEnumerable.Create(FPlatform.Devices[DeviceTypeMap[DeviceType]]);
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
  result := CLDevice.Create(FEnumerator.Current);
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
  result := CLPlatform.Create(FPlatforms[Index]);
end;

end.
