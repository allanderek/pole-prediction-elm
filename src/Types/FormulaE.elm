module Types.FormulaE exposing
    ( Entrant
    , EntrantId
    , Event
    , EventId
    , Season
    , currentChampion
    , currentSeason
    , entrantDecoder
    , eventDecoder
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
