unit Compute.OpenCL;

interface

uses
  System.SysUtils,
  cl, cl_platform,
  Compute.OpenCL.Detail;

type
//  TCLPlatformID = Compute.OpenCL.Detail.TCLPlatformID;
//  TCLDeviceID = Compute.OpenCL.Detail.TCLDeviceID;
  TLogProc = Compute.OpenCL.Detail.TLogProc;

  CLPlatform = record
  strict private
    FPlatform: Compute.OpenCL.Detail.ICLPlatform;
  private
    class function Create(const p: Compute.OpenCL.Detail.ICLPlatform): CLPlatform; static;
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

{ CLPlatform }

class function CLPlatform.Create(
  const p: Compute.OpenCL.Detail.ICLPlatform): CLPlatform;
begin
  result.FPlatform := p;
end;

end.
