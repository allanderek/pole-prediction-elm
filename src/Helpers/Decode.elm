module Helpers.Decode exposing
    ( emptyString
    , intAsBool
    , nullableInt
    , nullableString
    , stringAsInt
    )

import Json.Decode as Decode exposing (Decoder)


nullableAs : a -> Decoder a -> Decoder a
nullableAs defaultValue decoder =
    Decode.oneOf
        [ decoder
        , Decode.null defaultValue
        ]


nullableInt : Decoder Int
nullableInt =
    nullableAs 0 Decode.int


nullableString : Decoder String
nullableString =
    nullableAs "" Decode.string


emptyString : a -> Decoder a
emptyString value =
    let
        interpret : String -> Decoder a
        interpret s =
            case String.isEmpty s of
                True ->
                    Decode.succeed value

                False ->
                    Decode.fail "Expected an empty string"
    in
    Decode.string
        |> Decode.andThen interpret


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
