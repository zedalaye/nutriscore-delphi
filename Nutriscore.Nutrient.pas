unit Nutriscore.Nutrient;

interface

uses
  System.SysUtils;

type
  TNutrientData = record
  private
    FHasValue: Boolean;
    FValue: Double;
    function GetValue: Double;
  public
    class operator Initialize(out Dest: TNutrientData);
    class operator Assign(var Dest: TNutrientData; const [ref] Src: TNutrientData);

    class operator Implicit(AValue: Pointer): TNutrientData;
    class operator Implicit(AValue: Double): TNutrientData;
    class operator Implicit(const AValue: TNutrientData): Double;

    class operator Multiply(const Left: TNutrientData; Right: Integer): TNutrientData;
    class operator Divide(const Left, Right: TNutrientData): TNutrientData;

    class operator Equal(const Left: TNutrientData; Right: Double): Boolean;
    class operator GreaterThan(const Left: TNutrientData; Right: Double): Boolean;
    class operator GreaterThanOrEqual(const Left: TNutrientData; Right: Double): Boolean;
    class operator LessThanOrEqual(const Left: TNutrientData; Right: Double): Boolean;
    class operator LessThan(const Left: TNutrientData; Right: Double): Boolean;

    property HasValue: Boolean read FHasValue;
    property Value: Double read GetValue;
  end;

implementation

{ TNutrientData }

class operator TNutrientData.Initialize(out Dest: TNutrientData);
begin
  Dest.FHasValue := False;
end;

class operator TNutrientData.Assign(var Dest: TNutrientData;
  const [ref] Src: TNutrientData);
begin
  Dest.FHasValue := Src.FHasValue;
  Dest.FValue := Src.FValue;
end;

class operator TNutrientData.Implicit(AValue: Double): TNutrientData;
begin
  Result.FHasValue := True;
  Result.FValue := AValue;
end;

class operator TNutrientData.Implicit(AValue: Pointer): TNutrientData;
begin
  if AValue <> nil then
  begin
    Result.FHasValue := True;
    Result.FValue := Double(AValue^);
  end;
end;

class operator TNutrientData.Implicit(const AValue: TNutrientData): Double;
begin
  Result := AValue.Value; // MUST call GetValue() and raise error if no value
end;

function TNutrientData.GetValue: Double;
begin
  if FHasValue then
    Result := FValue
  else
    raise Exception.Create('Invalid Operation, NutrientData has no value');
end;

class operator TNutrientData.Multiply(const Left: TNutrientData;
  Right: Integer): TNutrientData;
begin
  if Left.FHasValue then
    Result := Left.FValue * Right;
end;

class operator TNutrientData.Divide(const Left,
  Right: TNutrientData): TNutrientData;
begin
  if Left.FHasValue and Right.FHasValue then
    Result := Left.FValue / Right.FValue;
end;

class operator TNutrientData.Equal(const Left: TNutrientData;
  Right: Double): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue = Right
  else
    Result := False;
end;

class operator TNutrientData.GreaterThan(const Left: TNutrientData;
  Right: Double): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue > Right
  else
    Result := False;
end;

class operator TNutrientData.GreaterThanOrEqual(const Left: TNutrientData;
  Right: Double): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue >= Right
  else
    Result := False;
end;

class operator TNutrientData.LessThan(const Left: TNutrientData;
  Right: Double): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue < Right
  else
    Result := False;
end;

class operator TNutrientData.LessThanOrEqual(const Left: TNutrientData;
  Right: Double): Boolean;
begin
  if Left.FHasValue then
    Result := Left.FValue <= Right
  else
    Result := False;
end;

end.
