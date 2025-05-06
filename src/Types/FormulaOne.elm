module Types.FormulaOne exposing
    ( Entrant
    , EntrantId
    , Event
    , EventId
    , Season
    , Session
    , SessionId
    , currentSeason
    , entrantDecoder
    , eventDecoder
    , sessionDecoder
    )

import Helpers.Decode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline


type alias Season =
    String


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
