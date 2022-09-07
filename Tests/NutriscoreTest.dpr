program NutriscoreTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  superobject,
  Nutriscore.Core in '..\Nutriscore.Core.pas',
  Nutriscore.Nutrient in '..\Nutriscore.Nutrient.pas',
  Nutriscore.Score in '..\Nutriscore.Score.pas';

const
  TEST_DIR = '.\OpenFoodFacts\PASS\';

function ScoreValue(const S: TScore): string;
begin
  if S.HasValue then
    Result := IntToStr(S.Value)
  else
    Result := 'null';
end;

procedure TestNutriscore(const Name: string; Klass: TNutriscoreClasses;
  const energy, saturated_fat, total_fat, sugar, sodium, fvnp, fibres, proteins: TNutrientData;
  Expected: TNutriscore);
const
  RESULT: array[Boolean] of string = ('FAIL', 'PASS');
var
  N: TNutrients;
  Score: TNutriscore;
{$if defined(DEBUG)}
  Debug: TScoreDebug;
{$endif}
begin
  case Klass of
    nscSpecific: N := TNutrients.NewGeneral(energy, saturated_fat, sugar, sodium, fvnp, fibres, proteins);
    nscCheese:   N := TNutrients.NewGeneral(energy, saturated_fat, sugar, sodium, fvnp, fibres, proteins);
    nscFats:     N := TNutrients.NewFats(energy, saturated_fat, total_fat, sugar, sodium, fvnp, fibres, proteins);
    nscDrinks:   N := TNutrients.NewDrinks(energy, sugar, fvnp);
    nscWater:    N := TNutrients.NewWater;
  end;

  Score := Nutriscore.Core.Nutriscore(Klass, N{$if defined(DEBUG)}, Debug{$endif});
  WriteLn(Name, ': ', Nutriscore.Core.NUTRISCORES[Score]{$if defined(DEBUG)}, ' (', ScoreValue(Debug.Score) ,')'{$endif}, ' - ', RESULT[Score = Expected]);
{$if defined(DEBUG)}
  WriteLn(' NegativeScore:', #9#9, ScoreValue(Debug.NegativeScore));
  WriteLn('  EnergyScore:', #9#9, ScoreValue(Debug.EnergyScore));
  WriteLn('  SaturatedFatScore', #9, ScoreValue(Debug.SaturatedFatScore));
  WriteLn('  SugarScore', #9#9, ScoreValue(Debug.SugarScore));
  WriteLn('  SodiumScore', #9#9, ScoreValue(Debug.SodiumScore));
  WriteLn(' PositiveScore', #9#9, ScoreValue(Debug.PositiveScore));
  WriteLn('  FVNPScore', #9#9, ScoreValue(Debug.FVNPScore));
  WriteLn('  FibreScore', #9#9, ScoreValue(Debug.FibreScore));
  WriteLn('  ProteinScore', #9#9, ScoreValue(Debug.ProteinScore));
  WriteLn;
{$endif}
end;

procedure TestFromFile(const FileName: string);
var
  Obj: ISuperObject;
  Name: string;

  function GetClass: TNutriscoreClasses;
  begin
    var ND := Obj['nutriscore_data'];
    if ObjectIsType(ND, stObject) then
      if ND.B['is_beverage'] then
        Result := nscDrinks
      else if ND.B['is_water'] then
        Result := nscWater
      else if ND.B['is_cheese'] then
        Result := nscCheese
      else if ND.B['is_fat'] then
        Result := nscFats
      else
        Result := nscSpecific
    else
      Result := nscSpecific;
  end;

  function GetNutriment(const Name: string; ZeroIfNotFound: Boolean = False): TNutrientData;
  begin
    if ObjectGetType(Obj['nutriments'][Name + '_100g']) <> stNull then
      Result := Obj['nutriments'].D[Name + '_100g']
    else if ObjectGetType(Obj['nutriments'][Name + '_prepared_100g']) <> stNull then
      Result := Obj['nutriments'].D[Name + '_prepared_100g']
    else if ZeroIfNotFound then
      Result := 0;
  end;

  function GetExpectedScore: TNutriscore;
  begin
    var NG := Obj.S['nutriscore_grade'];
         if NG = 'a' then Result := nsA
    else if NG = 'b' then Result := nsB
    else if NG = 'c' then Result := nsC
    else if NG = 'd' then Result := nsD
    else if NG = 'e' then Result := nsE
    else
      Result := nsUnknown;
  end;

begin
  Obj := TSuperObject.ParseFile(FileName, True);

(*
   "nutriments" : {
      "energy_100g" : 3378,
      "fat_100g" : 10,
      "fiber_100g" : 2,
      "fruits-vegetables-nuts-estimate-from-ingredients_100g" : 0,
      "fruits-vegetables-nuts-estimate-from-ingredients_serving" : 0,
      "nutrition-score-fr" : 19,
      "nutrition-score-fr_100g" : 19,
      "proteins_100g" : 5,
      "saturated-fat_100g" : 5,
      "sodium_100g" : 0,
      "sugars_100g" : 10
   },
*)

  TestNutriscore(Obj.S['categories'], GetClass,
    GetNutriment('energy'), GetNutriment('saturated-fat'), GetNutriment('fat'),
    GetNutriment('sugars'), GetNutriment('sodium'), GetNutriment('fruits-vegetables-nuts-estimate-from-ingredients', True),
    GetNutriment('fiber'), GetNutriment('proteins'),
    GetExpectedScore
  );
end;

var
  R: TSearchRec;

begin
  try
    TestNutriscore('Fromage Frais', nscSpecific, 459, 1.8, nil, 13.4, 0.1, 8, 0.6, 6.5, nsB);
    TestNutriscore('Fromage Frais + Fats', nscFats, 459, 1.8, 2.3, 13.4, 0.1, 8, 0.6, 6.5, nsC);
    TestNutriscore('Ice Tea', nscDrinks, 82, nil, nil, 4.5, 4, 0, nil, nil, nsD);
    TestNutriscore('Eau Minérale', nscWater, nil, nil, nil, nil, nil, nil, nil, nil, nsA);

    if FindFirst(TEST_DIR + '*.json', faAnyFile, R) = 0 then
    begin
      repeat
        TestFromFile(TEST_DIR + R.Name);
      until FindNext(R) <> 0;
      FindClose(R);
    end;

    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
