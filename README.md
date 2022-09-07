# Nutriscore for Delphi

Algorithm ported from [Nutriscore-Ruby](https://github.com/q-m/nutriscore-ruby) to Delphi

Requires a recent Delphi version that supports [Custom Managed Records](https://docwiki.embarcadero.com/RADStudio/Sydney/en/Custom_Managed_Records)

Nutriscore algorithm is described in the [Condition of Uses / Règlement d'Usage](https://www.santepubliquefrance.fr/determinants-de-sante/nutrition-et-activite-physique/articles/nutri-score#block-322597)

## Tests

In the Tests subdirectory, there is a small Delphi console application that run [tests from the OpenFoodFacts Server](https://github.com/openfoodfacts/openfoodfacts-server/tree/main/tests/unit/expected_test_results)

Tests that are expected to fail (in the FAIL subdirectory) are those which require to parse the ingredients list or the product categories (out of scope for this project)

## Usage

```delphi
var N: TNutrients;
N.energy := 459;
N.saturated_fat := 1.8;
N.sugar := 13.4;
N.sodium := 0.1;
N.fnvp := 8;
N.fibres := 0.6;
N.proteins := 6.5;

// Or, use the Nutrients Factory
var N := TNutrients.NewGeneral(459, 1.8, 13.4, 0.1, 8, 0.6, 6.5);

var Score := Nutriscore.Core.Nutriscore(nscSpecific, N);

case Score of
  nsUnknown: 
    WriteLn('Cannot compute Nutriscore');
else
  WriteLn(Nutriscore.Core.NUTRISCORES[Score]);
end;
```

## Units

See declaration of `TNutrient`, units have to be specified for 100g :

```delphi
  TNutrients = record
    { Negative Impact }
    energy: TNutrientData;        // kJ/100g
    saturated_fat: TNutrientData; // g/100g
    total_fat: TNutrientData;
    sugar: TNutrientData;         // g/100g
    sodium: TNutrientData;        // mg/100g = sel [mg/100g] / 2.5

    { Positive Impact }
    fvnp: TNutrientData;          // % [fruits, vegetables, nuls and pulses (+ rapeseed, walnuts and olive olds since oct. 2019)]
    fibres: TNutrientData;        // g/100g
    proteins: TNutrientData;      // g/100g
  end;
```

## Debugging

if `DEBUG` is defined, `Nutriscore.Core.Nutriscore()` function returns a `TScoreDebug` record which contains every intermediate computation to the final `score` value that is converted into a `TNutriscore` value.

## Notes

`Nutriscore.Nutrient.TNutrientData` and `Nutriscore.Score.TScore` are *Custom Managed Records*, they represent "Nullable" values.

```
  var NutrientData: TNutrientData := nil;
  Assert(NutrientData.HasValue = False);
```

```
  var NutrientData: TNutrientData := 459;
  Assert(NutrientData.HasValue = True);
  Assert(NutrientData.Value = 459);
```

(In)Equalities operators are defined on these records and required arithmetic operators.

These datatypes could have been implemented as a generic `TNullable<T>`

# Contributing

Pull requests are welcome.

Fork the project, create a new branch for your changes/fixes/..., commit, push and create a pull request.

# License

MIT License (see [LICENSE](LICENSE))
