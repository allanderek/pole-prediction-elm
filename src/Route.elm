module Route exposing
    ( Route(..)
    , href
    , parse
    , unparse
    )

import Html
import Html.Attributes
import Url
import Url.Builder
import Url.Parser as Parser exposing ((</>))


type Route
    = Home
    | Login
    | FormulaOne
    | FormulaE
    | Profile
    | NotFound


appPrefix : String
appPrefix =
    "app"


parse : Url.Url -> Route
parse url =
    let
        routeParser : Parser.Parser (Route -> b) b
        routeParser =
            Parser.oneOf
                [ Parser.top |> Parser.map Home
                , Parser.s appPrefix
                    </> Parser.oneOf
                            [ Parser.top |> Parser.map Home
                            , Parser.s "formula-one" |> Parser.map FormulaOne
                            , Parser.s "formula-e" |> Parser.map FormulaE
                            , Parser.s "login" |> Parser.map Login
                            , Parser.s "profile" |> Parser.map Profile
                            ]
                ]
    in
    url
        |> Parser.parse routeParser
        |> Maybe.withDefault NotFound


href : Route -> Html.Attribute msg
href route =
    Html.Attributes.href (unparse route)


unparse : Route -> String
unparse route =
    let
        parts : List String
        parts =
            case route of
                Home ->
                    []

                Login ->
                    [ "login" ]

                FormulaOne ->
                    [ "formula-one" ]

                FormulaE ->
                    [ "formula-e" ]

                Profile ->
                    [ "profile" ]

                NotFound ->
                    [ "not-found" ]
    in
    Url.Builder.absolute (appPrefix :: parts) []
