module Types.FormulaE exposing
    ( Entrant
    , EntrantId
    , Event
    , EventId
    , EventLeaderboard
    , Prediction
    , Result
    , ScoredPrediction
    , Season
    , currentChampion
    , currentSeason
    , emptyPrediction
    , entrantDecoder
    , eventDecoder
    , eventLeaderboardDecoder
    )

import Helpers.Decode
import Helpers.Rfc3339
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Time
import Types.User


type alias Season =
    String


currentChampion : Types.User.Id
currentChampion =
    5


currentSeason : Season
currentSeason =
    "2024-25"


type alias EventId =
    Int


type alias Event =
    { id : EventId
    , round : Int
    , name : String
    , country : String
    , circuit : String
    , startTime : Time.Posix
    , cancelled : Bool
    }


eventDecoder : Decoder Event
eventDecoder =
    Decode.succeed Event
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "round" Decode.int
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "country" Decode.string
        |> Pipeline.required "circuit" Decode.string
        |> Pipeline.required "date" Helpers.Rfc3339.decoder
        |> Pipeline.required "cancelled" Helpers.Decode.intAsBool


type alias EntrantId =
    Int


type alias Entrant =
    { id : EntrantId
    , number : Int
    , driver : String
    , teamFullName : String
    , teamShortName : String
    , teamPrimaryColor : String
    }


entrantDecoder : Decoder Entrant
entrantDecoder =
    Decode.succeed Entrant
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "number" Decode.int
        |> Pipeline.required "driver_name" Decode.string
        |> Pipeline.required "team_full_name" Decode.string
        |> Pipeline.required "team_short_name" Decode.string
        |> Pipeline.required "team_primary_color" Decode.string


type alias Prediction =
    { pole : EntrantId
    , fam : EntrantId
    , fastestLap : EntrantId
    , hgc : EntrantId
    , first : EntrantId
    , second : EntrantId
    , third : EntrantId
    , fdnf : EntrantId
    , safetyCar : Maybe Bool
    }


emptyPrediction : Prediction
emptyPrediction =
    { pole = 0
    , fam = 0
    , fastestLap = 0
    , hgc = 0
    , first = 0
    , second = 0
    , third = 0
    , fdnf = 0
    , safetyCar = Nothing
    }


type alias Result =
    Prediction


type alias ScoredPrediction =
    { userId : Types.User.Id
    , userName : String
    , prediction : Prediction
    , score : Int
    }


predictionDecoder : Decoder Prediction
predictionDecoder =
    let
        safetyCar : Decoder (Maybe Bool)
        safetyCar =
            let
                interpret : String -> Decoder (Maybe Bool)
                interpret str =
                    case str of
                        "yes" ->
                            Decode.succeed (Just True)

                        "no" ->
                            Decode.succeed (Just False)

                        "" ->
                            Decode.succeed Nothing

                        _ ->
                            Decode.fail "Invalid safety car value"
            in
            Decode.string |> Decode.andThen interpret
    in
    Decode.succeed Prediction
        |> Pipeline.required "pole" Decode.int
        |> Pipeline.required "fam" Decode.int
        |> Pipeline.required "fl" Decode.int
        |> Pipeline.required "hgc" Decode.int
        |> Pipeline.required "first" Decode.int
        |> Pipeline.required "second" Decode.int
        |> Pipeline.required "third" Decode.int
        |> Pipeline.required "fdnf" Decode.int
        |> Pipeline.required "safety_car" safetyCar


scoredPredictionDecoder : Decoder ScoredPrediction
scoredPredictionDecoder =
    Decode.succeed ScoredPrediction
        |> Pipeline.required "user_id" Decode.int
        |> Pipeline.required "user_name" Decode.string
        |> Pipeline.custom predictionDecoder
        |> Pipeline.required "score" Decode.int


type alias EventLeaderboard =
    { result : Maybe Result
    , predictions : List ScoredPrediction
    }


eventLeaderboardDecoder : Decoder EventLeaderboard
eventLeaderboardDecoder =
    Decode.succeed EventLeaderboard
        |> Pipeline.required "result" (Decode.nullable predictionDecoder)
        |> Pipeline.required "predictions" (Decode.list scoredPredictionDecoder)
