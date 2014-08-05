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

unit Compute.Future;

interface

uses
  Compute.Future.Detail;

type
  Future<T> = record
  strict private
    FImpl: IFuture<T>;
    function GetDone: boolean;
    function GetValue: T;
  public
    class operator Implicit(const Impl: IFuture<T>): Future<T>;

    procedure Wait;

    property Done: boolean read GetDone;
    property Value: T read GetValue;
  end;

implementation

{ Future<T> }

function Future<T>.GetDone: boolean;
begin
  result := FImpl.Done;
end;

function Future<T>.GetValue: T;
begin
  result := FImpl.Value;
end;

class operator Future<T>.Implicit(const Impl: IFuture<T>): Future<T>;
begin
  result.FImpl := Impl;
end;

procedure Future<T>.Wait;
begin
  FImpl.Wait;
end;

end.
