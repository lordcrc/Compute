unit Compute.Future.Detail;

interface

uses
  Compute.OpenCL;

type
  IFuture<T> = interface
    function GetDone: boolean;
    function GetValue: T;
    function GetPeekValue: T;
    function GetEvent: CLEvent;

    procedure Wait;

    property Done: boolean read GetDone;
    property Value: T read GetValue;
    property PeekValue: T read GetPeekValue; // non-blocking, a hack but hey
    property Event: CLEvent read GetEvent;
  end;

  TReadyFutureImpl<T> = class(TInterfacedObject, IFuture<T>)
  strict private
    FValue: T;
    FEvent: CLEvent;
  public
    // Value must be reference type
    constructor Create(const Value: T);

    function GetDone: boolean;
    function GetValue: T;
    function GetPeekValue: T;
    function GetEvent: CLEvent;

    procedure Wait;
  end;

  TOpenCLFutureImpl<T> = class(TInterfacedObject, IFuture<T>)
  strict private
    FValue: T;
    FEvent: CLEvent;
  public
    // Value must be reference type
    constructor Create(const Event: CLEvent; const Value: T);

    function GetDone: boolean;
    function GetValue: T;
    function GetPeekValue: T;
    function GetEvent: CLEvent;

    procedure Wait;

    property Event: CLEvent read FEvent;
  end;

implementation

{ TReadyFutureImpl<T> }

constructor TReadyFutureImpl<T>.Create(const Value: T);
begin
  inherited Create;

  FValue := Value;
end;

function TReadyFutureImpl<T>.GetDone: boolean;
begin
  result := True;
end;

function TReadyFutureImpl<T>.GetEvent: CLEvent;
begin
  result := nil;
end;

function TReadyFutureImpl<T>.GetPeekValue: T;
begin
  result := FValue;
end;

function TReadyFutureImpl<T>.GetValue: T;
begin
  result := FValue;
end;

procedure TReadyFutureImpl<T>.Wait;
begin

end;

{ TOpenCLFutureImpl<T> }

constructor TOpenCLFutureImpl<T>.Create(const Event: CLEvent; const Value: T);
begin
  inherited Create;

  FEvent := Event;
  FValue := Value;
end;

function TOpenCLFutureImpl<T>.GetDone: boolean;
begin
  result := (Event.CommandExecutionStatus = ExecutionStatusComplete);
end;

function TOpenCLFutureImpl<T>.GetEvent: CLEvent;
begin
  result := Event;
end;

function TOpenCLFutureImpl<T>.GetPeekValue: T;
begin
  result := FValue;
end;

function TOpenCLFutureImpl<T>.GetValue: T;
var
  done: boolean;
begin
  done := not GetDone();
  if (not done) then
    Wait();

  result := FValue;
end;

procedure TOpenCLFutureImpl<T>.Wait;
begin
  Event.Wait;
end;

end.
