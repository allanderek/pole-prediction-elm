module Helpers.Decode exposing
    ( intAsBool
    , stringAsInt
    )

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


stringAsInt : Decoder Int
stringAsInt =
    let
        interpret : String -> Decoder Int
        interpret string =
            case String.toInt string of
                Just n ->
                    Decode.succeed n

                Nothing ->
                    String.append "Expected an integer, but got: " string
                        |> Decode.fail
    in
    Decode.string
        |> Decode.andThen interpret
