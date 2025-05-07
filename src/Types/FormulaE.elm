module Types.FormulaE exposing
    ( Season
    , currentChampion
    , currentSeason
    )

import Types.User


type alias Season =
    String


currentChampion : Types.User.Id
currentChampion =
    5


currentSeason : Season
currentSeason =
    "2024-25"
