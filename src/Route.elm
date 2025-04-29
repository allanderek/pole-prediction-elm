module Route exposing
    ( Route(..)
    , parse
    , unparse
    )

import Url
import Url.Builder
import Url.Parser as Parser exposing ((</>))


type Route
    = Home
    | NotFound


appPrefix : String
appPrefix =
    "app"


parse : Url.Url -> Route
parse url =
    let
        routeParser : Parser.Parser (Route -> b) b
        routeParser =
            Parser.s appPrefix
                </> Parser.oneOf
                        [ Parser.top |> Parser.map Home
                        ]
    in
    url
        |> Parser.parse routeParser
        |> Maybe.withDefault NotFound


unparse : Route -> String
unparse route =
    let
        parts : List String
        parts =
            case route of
                Home ->
                    []

                NotFound ->
                    [ "not-found" ]
    in
    Url.Builder.absolute (appPrefix :: parts) []
