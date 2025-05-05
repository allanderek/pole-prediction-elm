module Types.FormulaOne exposing
    ( Event
    , EventId
    , Season
    , currentSeason
    , eventDecoder
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
