unit Nutriscore.Core;

interface

uses
  Nutriscore.Nutrient, Nutriscore.Score;

type
  TNutriscoreClasses = (nscSpecific, nscCheese, nscFats, nscDrinks, nscWater);
  TNutriscore = (nsUnknown, nsA, nsB, nsC, nsD, nsE);

const
  NUTRISCORES: array[TNutriscore] of Char = ('?', 'A', 'B', 'C', 'D', 'E');

type
  TNutrients = record
    { Negative Impact }
    energy: TNutrientData;        // kJ/100g
    saturated_fat: TNutrientData; // g/100g
    total_fat: TNutrientData;
    sugar: TNutrientData;         // g/100g
    sodium: TNutrientData;        // mg/100g <=> salt [mg/100g] / 2.5

    { Positive Impact }
    fvnp: TNutrientData;          // % [fruits, vegetables, nuls and pulses (+ rapeseed, walnuts and olive olds since oct. 2019)]
    fibres: TNutrientData;        // g/100g
    proteins: TNutrientData;      // g/100g

    // nscSpecific / nscCheese
    class function NewGeneral(const energy, saturated_fat, sugar, sodium, fvnp, fibres, proteins: TNutrientData): TNutrients; static;
    // nscFats
    class function NewFats(const energy, saturated_fat, total_fat, sugar, sodium, fvnp, fibres, proteins: TNutrientData): TNutrients; static;
    // nscDrinks
    class function NewDrinks(const energy, sugar, fvnp: TNutrientData): TNutrients; static;
    // nscWater
    class function NewWater: TNutrients; static;
  end;

{$if defined(DEBUG)}
  TScoreDebug = record
    EnergyScore: TScore;
    SaturatedFatScore: TScore;
    SugarScore: TScore;
    SodiumScore: TScore;
    NegativeScore: TScore;

    FVNPScore: TScore;
    FibreScore: TScore;
    ProteinScore: TScore;
    PositiveScore: TScore;

    Score: TScore;
  end;
{$endif}

  TNutriscoreGeneral = class abstract
  protected
  {$if defined(DEBUG)}
    FDebug: TScoreDebug;
  {$endif}

    { Negative }
    function EnergyScore(const Value: TNutrientData): TScore; virtual;
    function SaturatedFatScore(const Value, _Total: TNutrientData): TScore; virtual;
    function SugarScore(const Value: TNutrientData): TScore; virtual;
    function SodiumScore(const Value: TNutrientData): TScore; virtual;

    { Positive }
    function FVNPScore(const Value: TNutrientData): TScore; virtual;
    function FibreScore(const Value: TNutrientData): TScore; virtual;
    function ProteinScore(const Value: TNutrientData): TScore; virtual;

    function NegativeScore(const Nutrients: TNutrients): TScore; virtual;
    function PositiveScore(const Nutrients: TNutrients): TScore; virtual;

    function Score(const Nutrients: TNutrients): TScore; virtual;
    function Nutriscore(const Score: TScore): TNutriscore; virtual;
  public
    function Compute(const Nutrients: TNutrients): TNutriscore; virtual;
  end;

  TNutriscoreKlass = class of TNutriscoreGeneral;

  TNutriscoreCheese = class(TNutriscoreGeneral)
    // uses TNutriscoreGeneral.Score() (no specific cases)
  end;

  TNutriscoreSpecific = class(TNutriscoreGeneral)
  private
    function PositiveScoreWithoutProteins(const Nutrients: TNutrients): TScore;
  protected
    function Score(const Nutrients: TNutrients): TScore; override;
  end;

  TNutriscoreFats = class(TNutriscoreGeneral)
  private
    function SaturatedFatPercent(const Value, Total: TNutrientData): TNutrientData;
  protected
    function SaturatedFatScore(const Value, Total: TNutrientData): TScore; override;
  end;

  TNutriscoreDrinks = class(TNutriscoreGeneral)
  protected
    function EnergyScore(const Value: TNutrientData): TScore; override;
    function SugarScore(const Value: TNutrientData): TScore; override;
    function FVNPScore(const Value: TNutrientData): TScore; override;

    function NegativeScore(const Nutrients: TNutrients): TScore; override;
    function PositiveScore(const Nutrients: TNutrients): TScore; override;

    function Nutriscore(const Score: TScore): TNutriscore; override;
  end;

  TNutriscoreWater = class(TNutriscoreDrinks)
  protected
    function Nutriscore(const _Score: TScore): TNutriscore; override;
  end;

function Nutriscore(ProductClass: TNutriscoreClasses; const Nutrients: TNutrients
  {$if defined(DEBUG)}; var Debug: TScoreDebug{$endif}): TNutriscore;

implementation

function Nutriscore(ProductClass: TNutriscoreClasses; const Nutrients: TNutrients
  {$if defined(DEBUG)}; var Debug: TScoreDebug{$endif}): TNutriscore;
const
  KLASSES: array[TNutriscoreClasses] of TNutriscoreKlass = (
    TNutriscoreSpecific,
    TNutriscoreCheese,
    TNutriscoreFats,
    TNutriscoreDrinks, TNutriscoreWater
  );
begin
  var K := KLASSES[ProductClass].Create;
  try
    Result := K.Compute(Nutrients);
  {$if defined(DEBUG)}
    Debug := K.FDebug;
  {$endif}
  finally
    K.Free;
  end;
end;

{ TNutriscoreGeneral }

function TNutriscoreGeneral.Compute(const Nutrients: TNutrients): TNutriscore;
begin
  Result := Nutriscore(Score(Nutrients));
end;

function TNutriscoreGeneral.Nutriscore(const Score: TScore): TNutriscore;
begin
  if Score.HasValue then
         if Score <  0 then Result := nsA
    else if Score <  3 then Result := nsB
    else if Score < 11 then Result := nsC
    else if Score < 19 then Result := nsD
    else
      Result := nsE
  else
    Result := nsUnknown;
end;

function TNutriscoreGeneral.Score(const Nutrients: TNutrients): TScore;
begin
  Result := NegativeScore(Nutrients) - PositiveScore(Nutrients);
{$if defined(DEBUG)}
  FDebug.Score := Result;
{$endif}
end;

function TNutriscoreGeneral.NegativeScore(const Nutrients: TNutrients): TScore;
begin
  Result := EnergyScore(Nutrients.energy)
          + SaturatedFatScore(Nutrients.saturated_fat, Nutrients.total_fat)
          + SugarScore(Nutrients.sugar)
          + SodiumScore(Nutrients.sodium);
{$if defined(DEBUG)}
  FDebug.NegativeScore := Result;
{$endif}
end;

function TNutriscoreGeneral.PositiveScore(const Nutrients: TNutrients): TScore;
begin
  Result := FVNPScore(Nutrients.fvnp)
          + FibreScore(Nutrients.fibres)
          + ProteinScore(Nutrients.proteins);
{$if defined(DEBUG)}
  FDebug.PositiveScore := Result;
{$endif}
end;

function TNutriscoreGeneral.EnergyScore(const Value: TNutrientData): TScore;
begin
  if Value.HasValue then
         if Value > 3350 then Result := 10
    else if Value > 3015 then Result :=  9
    else if Value > 2680 then Result :=  8
    else if Value > 2345 then Result :=  7
    else if Value > 2010 then Result :=  6
    else if Value > 1675 then Result :=  5
    else if Value > 1340 then Result :=  4
    else if Value > 1005 then Result :=  3
    else if Value >  670 then Result :=  2
    else if Value >  335 then Result :=  1
    else
      Result := 0;
{$if defined(DEBUG)}
  FDebug.EnergyScore := Result;
{$endif}
end;

function TNutriscoreGeneral.SaturatedFatScore(const Value, _Total: TNutrientData): TScore;
begin
  if Value.HasValue then
  begin
    var V := Round(Value.Value);

         if V > 10 then Result := 10
    else if V >  9 then Result :=  9
    else if V >  8 then Result :=  8
    else if V >  7 then Result :=  7
    else if V >  6 then Result :=  6
    else if V >  5 then Result :=  5
    else if V >  4 then Result :=  4
    else if V >  3 then Result :=  3
    else if V >  2 then Result :=  2
    else if V >  1 then Result :=  1
    else
      Result := 0;
  end;
{$if defined(DEBUG)}
  FDebug.SaturatedFatScore := Result;
{$endif}
end;

function TNutriscoreGeneral.SodiumScore(const Value: TNutrientData): TScore;
begin
  if Value.HasValue then
  begin
    var V := Value.Value * 1000;

         if V > 900 then Result := 10
    else if V > 810 then Result :=  9
    else if V > 720 then Result :=  8
    else if V > 630 then Result :=  7
    else if V > 540 then Result :=  6
    else if V > 450 then Result :=  5
    else if V > 360 then Result :=  4
    else if V > 270 then Result :=  3
    else if V > 180 then Result :=  2
    else if V >  90 then Result :=  1
    else
      Result := 0;
  end;
{$if defined(DEBUG)}
  FDebug.SodiumScore := Result;
{$endif}
end;

function TNutriscoreGeneral.SugarScore(const Value: TNutrientData): TScore;
begin
  if Value.HasValue then
         if Value > 45   then Result := 10
    else if Value > 40   then Result :=  9
    else if Value > 36   then Result :=  8
    else if Value > 31   then Result :=  7
    else if Value > 27   then Result :=  6
    else if Value > 22.5 then Result :=  5
    else if Value > 18   then Result :=  4
    else if Value > 13.5 then Result :=  3
    else if Value >  9   then Result :=  2
    else if Value >  4.5 then Result :=  1
    else
      Result := 0;
{$if defined(DEBUG)}
  FDebug.SugarScore := Result;
{$endif}
end;

function TNutriscoreGeneral.FVNPScore(const Value: TNutrientData): TScore;
begin
  if Value.HasValue then
         if Value > 80 then Result :=  5
    else if Value > 60 then Result :=  2
    else if Value > 40 then Result :=  1
    else
      Result := 0;
{$if defined(DEBUG)}
  FDebug.FVNPScore := Result;
{$endif}
end;

function TNutriscoreGeneral.FibreScore(const Value: TNutrientData): TScore;
begin
  if Value.HasValue then
         if Value > 4.7 then Result :=  5
    else if Value > 3.7 then Result :=  4
    else if Value > 2.8 then Result :=  3
    else if Value > 1.9 then Result :=  2
    else if Value > 0.9 then Result :=  1
    else
      Result := 0;
{$if defined(DEBUG)}
  FDebug.FibreScore := Result;
{$endif}
end;

function TNutriscoreGeneral.ProteinScore(const Value: TNutrientData): TScore;
begin
  if Value.HasValue then
         if Value > 8.0 then Result :=  5
    else if Value > 6.4 then Result :=  4
    else if Value > 4.8 then Result :=  3
    else if Value > 3.2 then Result :=  2
    else if Value > 1.6 then Result :=  1
    else
      Result := 0;
{$if defined(DEBUG)}
  FDebug.ProteinScore := Result;
{$endif}
end;

{ TNutriscoreDrinks }

function TNutriscoreDrinks.EnergyScore(const Value: TNutrientData): TScore;
begin
  if Value.HasValue then
         if Value  =   0 then Result := 0
    else if Value <=  30 then Result := 1
    else if Value <=  60 then Result := 2
    else if Value <=  90 then Result := 3
    else if Value <= 120 then Result := 4
    else if Value <= 150 then Result := 5
    else if Value <= 180 then Result := 6
    else if Value <= 210 then Result := 7
    else if Value <= 240 then Result := 8
    else if Value <= 270 then Result := 9
    else
      Result := 10;
{$if defined(DEBUG)}
  FDebug.EnergyScore := Result;
{$endif}
end;

function TNutriscoreDrinks.SugarScore(const Value: TNutrientData): TScore;
begin
  if Value.HasValue then
         if Value =  0   then Result := 0
    else if Value <  1.5 then Result := 1
    else if Value <  3   then Result := 2
    else if Value <  4.5 then Result := 3
    else if Value <  6   then Result := 4
    else if Value <  7.5 then Result := 5
    else if Value <  9   then Result := 6
    else if Value < 10.5 then Result := 7
    else if Value < 12   then Result := 8
    else if Value < 13.5 then Result := 9
    else
      Result := 10;
{$if defined(DEBUG)}
  FDebug.SugarScore := Result;
{$endif}
end;

function TNutriscoreDrinks.FVNPScore(const Value: TNutrientData): TScore;
begin
  if Value.HasValue then
         if Value > 80 then Result := 10
    else if Value > 60 then Result :=  4
    else if Value > 40 then Result :=  2
    else
      Result := 0;
{$if defined(DEBUG)}
  FDebug.FVNPScore := Result;
{$endif}
end;

function TNutriscoreDrinks.NegativeScore(const Nutrients: TNutrients): TScore;
begin
  Result := EnergyScore(Nutrients.energy)
          + SugarScore(Nutrients.sugar);
{$if defined(DEBUG)}
  FDebug.NegativeScore := Result;
{$endif}
end;

function TNutriscoreDrinks.PositiveScore(const Nutrients: TNutrients): TScore;
begin
  Result := FVNPScore(Nutrients.fvnp);
{$if defined(DEBUG)}
  FDebug.PositiveScore := Result;
{$endif}
end;

function TNutriscoreDrinks.Nutriscore(const Score: TScore): TNutriscore;
begin
  if Score.HasValue then
    { Mineral Water has Nutriscore A hard coded }
         if Score <  2 then Result := nsB
    else if Score <  6 then Result := nsC
    else if Score < 10 then Result := nsD
    else
      Result := nsE
  else
    Result := nsUnknown;
end;

{ TNutriscoreWater }

function TNutriscoreWater.Nutriscore(const _Score: TScore): TNutriscore;
begin
  Result := nsA;
end;

{ TNutriscoreFats }

function TNutriscoreFats.SaturatedFatPercent(const Value, Total: TNutrientData): TNutrientData;
begin
  if Total > 0 then
    Result := (Value * 100) / Total;
end;

function TNutriscoreFats.SaturatedFatScore(const Value, Total: TNutrientData): TScore;
begin
  var V := SaturatedFatPercent(Value, Total);

  if V.HasValue then
         if V < 10 then Result := 0
    else if V < 16 then Result := 1
    else if V < 22 then Result := 2
    else if V < 28 then Result := 3
    else if V < 34 then Result := 4
    else if V < 40 then Result := 5
    else if V < 46 then Result := 6
    else if V < 52 then Result := 7
    else if V < 58 then Result := 8
    else if V < 64 then Result := 9
    else
      Result := 10;
{$if defined(DEBUG)}
  FDebug.SaturatedFatScore := Result;
{$endif}
end;

{ TNutriscoreSpecific }

function TNutriscoreSpecific.PositiveScoreWithoutProteins(
  const Nutrients: TNutrients): TScore;
begin
  Result := FVNPScore(Nutrients.fvnp)
          + FibreScore(Nutrients.fibres);
{$if defined(DEBUG)}
  FDebug.PositiveScore := Result;
{$endif}
end;

function TNutriscoreSpecific.Score(const Nutrients: TNutrients): TScore;
begin
  var NS := NegativeScore(Nutrients);

  if NS.HasValue then
    if NS < 11 then
      Result := NS - PositiveScore(Nutrients)
    else // NS >= 11
      if FVNPScore(Nutrients.fvnp) = 5 then
        Result := NS - PositiveScore(Nutrients)
      else // FNVPScore(fnvp) < 5
        Result := NS - PositiveScoreWithoutProteins(Nutrients);
{$if defined(DEBUG)}
  FDebug.Score := Result;
{$endif}
end;

{ TNutrients }

class function TNutrients.NewGeneral(const energy, saturated_fat, sugar, sodium,
  fvnp, fibres, proteins: TNutrientData): TNutrients;
begin
  Result.energy := energy;
  Result.saturated_fat := saturated_fat;
  Result.sugar := sugar;
  Result.sodium := sodium;
  Result.fvnp := fvnp;
  Result.fibres := fibres;
  Result.proteins := proteins;
end;

class function TNutrients.NewFats(const energy, saturated_fat, total_fat, sugar,
  sodium, fvnp, fibres, proteins: TNutrientData): TNutrients;
begin
  Result.energy := energy;
  Result.saturated_fat := saturated_fat;
  Result.total_fat := total_fat;
  Result.sugar := sugar;
  Result.sodium := sodium;
  Result.fvnp := fvnp;
  Result.fibres := fibres;
  Result.proteins := proteins;
end;

class function TNutrients.NewDrinks(const energy, sugar,
  fvnp: TNutrientData): TNutrients;
begin
  Result.energy := energy;
  Result.sugar := sugar;
  Result.fvnp := fvnp;
end;

class function TNutrients.NewWater: TNutrients;
begin
  // Water don't need any nutrient data to get a A score.
end;

end.
