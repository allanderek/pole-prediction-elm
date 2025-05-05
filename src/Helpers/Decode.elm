module Helpers.Decode exposing (intAsBool)

import Json.Decode as Decode exposing (Decoder)


intAsBool : Decoder Bool
intAsBool =
    let
        asBool : Int -> Bool
        asBool n =
            n /= 0
    in
    Decode.int
        |> Decode.map asBool
