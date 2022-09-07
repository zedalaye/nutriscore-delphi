unit Nutriscore.Score;

interface

uses
  System.SysUtils;

type
  TScore = record
  private
    FHasValue: Boolean;
    FValue: Integer;
    function GetValue: Integer;
  public
    class operator Initialize(out Dest: TScore);
    class operator Assign(var Dest: TScore; const [ref] Src: TScore);

    class operator Implicit(AValue: Pointer): TScore;
    class operator Implicit(AValue: Integer): TScore;
    class operator Implicit(const AValue: TScore): Integer;

    class operator Add(const Left, Right: TScore): TScore;
    class operator Subtract(const Left, Right: TScore): TScore;

    class operator Equal(const Left: TScore; Right: Integer): Boolean;
    class operator GreaterThan(const Left: TScore; Right: Integer): Boolean;
    class operator GreaterThanOrEqual(const Left: TScore; Right: Integer): Boolean;
    class operator LessThanOrEqual(const Left: TScore; Right: Integer): Boolean;
    class operator LessThan(const Left: TScore; Right: Integer): Boolean;

    property HasValue: Boolean read FHasValue;
    property Value: Integer read GetValue;
  end;

implementation

{ TScore }

class operator TScore.Initialize(out Dest: TScore);
begin
  Dest.FHasValue := False;
end;

class operator TScore.Assign(var Dest: TScore; const [ref] Src: TScore);
begin
  Dest.FHasValue := Src.FHasValue;
  Dest.FValue := Src.FValue;
end;

class operator TScore.Implicit(AValue: Pointer): TScore;
begin
  if AValue <> nil then
  begin
    Result.FHasValue := True;
    Result.FValue := Integer(AValue^);
  end;
end;

class operator TScore.Implicit(AValue: Integer): TScore;
begin
  Result.FHasValue := True;
  Result.FValue := AValue;
end;

class operator TScore.Implicit(const AValue: TScore): Integer;
begin
  Result := AValue.Value; // MUST call GetValue() and raise error if no value
end;

function TScore.GetValue: Integer;
begin
  if FHasValue then
    Result := FValue
  else
    raise Exception.Create('Invalid Operation, Score has no value');
end;

class operator TScore.Add(const Left, Right: TScore): TScore;
begin
  if Left.FHasValue and Right.FHasValue then
    Result := Left.FValue + Right.FValue;
end;

class operator TScore.Subtract(const Left, Right: TScore): TScore;
begin
  if Left.FHasValue and Right.FHasValue then
    Result := Left.FValue - Right.FValue;
end;

class operator TScore.Equal(const Left: TScore; Right: Integer): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue = Right
  else
    Result := False;
end;

class operator TScore.GreaterThan(const Left: TScore; Right: Integer): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue > Right
  else
    Result := False;
end;

class operator TScore.GreaterThanOrEqual(const Left: TScore; Right: Integer): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue >= Right
  else
    Result := False;
end;

class operator TScore.LessThan(const Left: TScore; Right: Integer): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue < Right
  else
    Result := False;
end;

class operator TScore.LessThanOrEqual(const Left: TScore; Right: Integer): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue <= Right
  else
    Result := False;
end;

end.
