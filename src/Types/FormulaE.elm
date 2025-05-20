module Types.FormulaE exposing
    ( Event
    , EventId
    , Season
    , currentChampion
    , currentSeason
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
    , date : Time.Posix
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
