unit Compute.Future.Detail;

interface

uses
  Compute.OpenCL;

type
  IFuture<T> = interface
    function GetDone: boolean;
    function GetValue: T;

    procedure Wait;

    property Done: boolean read GetDone;
    property Value: T read GetValue;
  end;

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

implementation

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
  Context.WaitForEvents([Event]);
end;

end.
