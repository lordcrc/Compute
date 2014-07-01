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

unit Compute.Common;

interface

uses
  System.SysUtils,
  Generics.Defaults,
  Generics.Collections,
  cl_platform;

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

  IDictionary<K, V> = interface
    function GetCount: UInt32;
    function GetItem(const Key: K): V;
    procedure SetItem(const Key: K; const Value: V);
    function GetEmpty: Boolean;
    function GetContains(const Key: K): Boolean;

    procedure Clear;
    function Remove(const Key: K): Boolean;

    property Empty: Boolean read GetEmpty;
    property Count: UInt32 read GetCount;
    property Item[const Key: K]: V read GetItem write SetItem; default;
    property Contains[const Key: K]: Boolean read GetContains;
  end;

  TDictionaryImpl<K, V> = class(TInterfacedObject, IDictionary<K, V>)
  private
    type
      TDict = Generics.Collections.TDictionary<K, V>;
  private
    FDict: TDict;
  public
    constructor Create(Comparer: Generics.Defaults.IEqualityComparer<K> = nil);
    destructor Destroy; override;

    function GetCount: UInt32;
    function GetItem(const Key: K): V;
    procedure SetItem(const Key: K; const Value: V);
    function GetEmpty: Boolean;
    function GetContains(const Key: K): Boolean;

    procedure Clear;
    function Remove(const Key: K): Boolean;
  end;

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

  // OpenCL

  TCLStatus = TCL_int;

  ECLException = class(Exception)
  strict private
    FStatus: TCLStatus;
  public
    constructor Create(const Status: TCLStatus);
    property Status: TCLStatus read FStatus;
  end;


implementation

uses
  System.RTLConsts, cl;

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

{ TDictionaryImpl<K, V> }

procedure TDictionaryImpl<K, V>.Clear;
begin
  FDict.Clear;
end;

constructor TDictionaryImpl<K, V>.Create(Comparer: Generics.Defaults.IEqualityComparer<K> = nil);
begin
  inherited Create;

  FDict := TDict.Create(Comparer)
end;

destructor TDictionaryImpl<K, V>.Destroy;
begin
  FDict.Free;

  inherited;
end;

function TDictionaryImpl<K, V>.GetContains(const Key: K): Boolean;
begin
  result := FDict.ContainsKey(Key);
end;

function TDictionaryImpl<K, V>.GetCount: UInt32;
begin
  result := FDict.Count;
end;

function TDictionaryImpl<K, V>.GetEmpty: Boolean;
begin
  result := FDict.Count = 0;
end;

function TDictionaryImpl<K, V>.GetItem(const Key: K): V;
begin
  if not FDict.TryGetValue(Key, result) then
  begin
    result := Default(V);
    FDict.Add(Key, result);
  end;
end;

function TDictionaryImpl<K, V>.Remove(const Key: K): Boolean;
begin
  result := FDict.ContainsKey(Key);
  if result then
    FDict.Remove(Key);
end;

procedure TDictionaryImpl<K, V>.SetItem(const Key: K; const Value: V);
begin
  FDict.AddOrSetValue(Key, Value);
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
  result := (FIndex + 1) < Length(FItems);
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

{ ECLException }

constructor ECLException.Create(const Status: TCLStatus);
var
  msg: string;
begin
  msg := cl.StatusToStr(Status);
  inherited Create(msg);
end;

end.
