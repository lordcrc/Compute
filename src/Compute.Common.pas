unit Compute.Common;

interface

uses
  Generics.Collections;

type
  IList<T> = interface
    procedure Add(const Item: T);
    procedure Delete(const ItemIndex: integer);

    function GetCount: integer;
    function GetItem(const Index: integer): T;
    procedure SetItem(const Index: integer; const Value: T);

    function ToArray(): TArray<T>;

    property Count: integer read GetCount;
    property Items[const Index: integer]: T read GetItem write SetItem; default;
  end;

  TListImpl<T> = class(TInterfacedObject, IList<T>)
  strict private
    FList: Generics.Collections.TList<T>;

    procedure Add(const Item: T);
    procedure Delete(const ItemIndex: integer);

    function ToArray(): TArray<T>;

    function GetCount: integer;
    function GetItem(const Index: integer): T;
    procedure SetItem(const Index: integer; const Value: T);
  public
    constructor Create;
    destructor Destroy; override;
  end;

  IStack<T> = interface
    procedure Push(const Item: T);
    function Pop(): T;

    function GetCount: integer;
    function GetTop: T;

    property Count: integer read GetCount;
    property Top: T read GetTop;
  end;

  TStackImpl<T> = class(TInterfacedObject, IStack<T>)
  strict private
    FList: Generics.Collections.TList<T>;

    procedure Push(const Item: T);
    function Pop(): T;

    function GetCount: integer;
    function GetTop: T;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.RTLConsts;

{ TListImpl<T> }

procedure TListImpl<T>.Add(const Item: T);
begin
  FList.Add(Item);
end;

constructor TListImpl<T>.Create;
begin
  inherited Create;

  FList := Generics.Collections.TList<T>.Create;
end;

procedure TListImpl<T>.Delete(const ItemIndex: integer);
begin
  FList.Delete(ItemIndex);
end;

destructor TListImpl<T>.Destroy;
begin
  FList.Free;

  inherited;
end;

function TListImpl<T>.GetCount: integer;
begin
  result := FList.Count;
end;

function TListImpl<T>.GetItem(const Index: integer): T;
begin
  result := FList[Index];
end;

procedure TListImpl<T>.SetItem(const Index: integer; const Value: T);
begin
  FList[Index] := Value;
end;

function TListImpl<T>.ToArray: TArray<T>;
begin
  result := FList.ToArray();
end;

{ TStackImpl<T> }

constructor TStackImpl<T>.Create;
begin
  inherited Create;

  FList := Generics.Collections.TList<T>.Create;
end;

destructor TStackImpl<T>.Destroy;
begin
  FList.Free;

  inherited;
end;

function TStackImpl<T>.GetCount: integer;
begin
  result := FList.Count;
end;

function TStackImpl<T>.GetTop: T;
begin
  result := FList.Last;
end;

function TStackImpl<T>.Pop: T;
begin
  result := FList.Last;
  FList.Delete(FList.Count-1);
end;

procedure TStackImpl<T>.Push(const Item: T);
begin
  FList.Add(Item);
end;

end.
