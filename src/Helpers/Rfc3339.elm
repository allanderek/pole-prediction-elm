module Helpers.Rfc3339 exposing (decoder)

import Json.Decode as Decode exposing (Decoder)
import Parser.Advanced
import Rfc3339
import Time


decoder : Decoder Time.Posix
decoder =
    let
        -- This uses wolfadex's parser, I'm not entirely sure if actually using a parser
        -- library isn't a bit overkill for Rfc3339, we could just use split etc.
        parse : String -> Decoder Time.Posix
        parse input =
            case Parser.Advanced.run Rfc3339.dateTimeOffsetParser input of
                Err _ ->
                    String.join "\n"
                        [ "Invalid RFC3399 date:"
                        , input
                        ]
                        |> Decode.fail

                Ok withOffset ->
                    Decode.succeed withOffset.instant
    in
    Decode.string
        |> Decode.andThen parse
