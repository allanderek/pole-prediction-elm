module Types.FormulaOne exposing
    ( Entrant
    , EntrantId
    , Event
    , EventId
    , ScoredPredictionRow
    , Season
    , Session
    , SessionId
    , SessionLeaderboard
    , SessionLeaderboardRow
    , currentChampion
    , currentSeason
    , entrantDecoder
    , eventDecoder
    , scoredPredictionRowDecoder
    , scoredPredictionRowsToSessionLeaderboard
    , sessionDecoder
    )

import Dict exposing (Dict)
import Helpers.Decode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Types.User


type alias Season =
    String


currentChampion : Types.User.Id
currentChampion =
    5


currentSeason : Season
currentSeason =
    "2025"


type alias EventId =
    Int


type alias Event =
    { id : EventId
    , round : Int
    , name : String
    , isSprint : Bool
    }


eventDecoder : Decoder Event
eventDecoder =
    Decode.succeed Event
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "round" Decode.int
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "isSprint" Helpers.Decode.intAsBool


type alias SessionId =
    Int


type alias Session =
    { id : SessionId
    , name : String
    , half_points : Bool

    -- , startTime : String
    , cancelled : Bool
    , fastestLap : Bool
    }


sessionDecoder : Decoder Session
sessionDecoder =
    Decode.succeed Session
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "half_points" Helpers.Decode.intAsBool
        -- |> Pipeline.required "start_time" Decode.string
        |> Pipeline.required "cancelled" Helpers.Decode.intAsBool
        |> Pipeline.required "fastest_lap" Helpers.Decode.intAsBool


type alias EntrantId =
    Int


type alias Entrant =
    { id : EntrantId
    , number : Int
    , driver : String
    , teamFullName : String
    , teamShortName : String
    , teamPrimaryColor : String
    , teamSecondaryColor : String
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
        |> Pipeline.required "team_secondary_color" Decode.string


type alias ScoredPredictionRow =
    { userId : Types.User.Id
    , userName : String
    , predictedPosition : Int
    , actualPosition : Int
    , driverName : String
    , score : Int
    }


scoredPredictionRowDecoder : Decoder ScoredPredictionRow
scoredPredictionRowDecoder =
    Decode.succeed ScoredPredictionRow
        |> Pipeline.required "user_id" Decode.int
        |> Pipeline.required "user_name" Decode.string
        |> Pipeline.required "predicted_position" Decode.int
        |> Pipeline.required "actual_position" Decode.int
        |> Pipeline.required "driver_name" Decode.string
        |> Pipeline.required "score" Decode.int


type alias SessionLeaderboard =
    List SessionLeaderboardRow


type alias SessionLeaderboardRow =
    { userId : Types.User.Id
    , userName : String
    , total : Int
    , rows : List ScoredPredictionRow
    }


scoredPredictionRowsToSessionLeaderboard : List ScoredPredictionRow -> SessionLeaderboard
scoredPredictionRowsToSessionLeaderboard rows =
    let
        processRow : ScoredPredictionRow -> Dict Types.User.Id SessionLeaderboardRow -> Dict Types.User.Id SessionLeaderboardRow
        processRow row accumulator =
            let
                updateLeaderboardRow : Maybe SessionLeaderboardRow -> Maybe SessionLeaderboardRow
                updateLeaderboardRow mRow =
                    case mRow of
                        Just leaderboardRow ->
                            Just
                                { leaderboardRow
                                    | total = leaderboardRow.total + row.score
                                    , rows = List.append leaderboardRow.rows [ row ]
                                }

                        Nothing ->
                            Just
                                { userId = row.userId
                                , userName = row.userName
                                , total = row.score
                                , rows = [ row ]
                                }
            in
            Dict.update row.userId updateLeaderboardRow accumulator
    in
    List.foldl processRow Dict.empty rows
        |> Dict.values
        |> List.sortBy .total
