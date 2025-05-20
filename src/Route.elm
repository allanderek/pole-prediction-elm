module Route exposing
    ( Route(..)
    , href
    , parse
    , unparse
    )

import Html
import Html.Attributes
import Types.FormulaE
import Types.FormulaOne
import Url
import Url.Builder
import Url.Parser as Parser exposing ((</>))


type Route
    = Home
    | Login
    | FormulaOne (Maybe Types.FormulaOne.Season)
    | FormulaOneEvent Types.FormulaOne.Season Types.FormulaOne.EventId
    | FormulaOneSession Types.FormulaOne.Season Types.FormulaOne.EventId Types.FormulaOne.SessionId
    | FormulaE (Maybe Types.FormulaE.Season)
    | FormulaEEvent Types.FormulaE.Season Types.FormulaE.EventId
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
                            , Parser.s "formula-one" |> Parser.map (FormulaOne Nothing)
                            , Parser.s "formula-one"
                                </> Parser.s "season"
                                </> Parser.string
                                |> Parser.map (FormulaOne << Just)
                            , Parser.s "formula-one"
                                </> Parser.s "event"
                                </> Parser.string
                                </> Parser.int
                                |> Parser.map FormulaOneEvent
                            , Parser.s "formula-one"
                                </> Parser.s "session"
                                </> Parser.string
                                </> Parser.int
                                </> Parser.int
                                |> Parser.map FormulaOneSession
                            , Parser.s "formula-e"
                                </> Parser.s "season"
                                </> Parser.string
                                |> Parser.map (FormulaE << Just)
                            , Parser.s "formula-e" |> Parser.map (FormulaE Nothing)
                            , Parser.s "formula-e"
                                </> Parser.s "event"
                                </> Parser.string
                                </> Parser.int
                                |> Parser.map FormulaEEvent
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

                FormulaOne Nothing ->
                    [ "formula-one" ]

                FormulaOne (Just season) ->
                    [ "formula-one", "season", season ]

                FormulaOneEvent season eventId ->
                    [ "formula-one", "event", season, String.fromInt eventId ]

                FormulaOneSession season eventId sessionId ->
                    [ "formula-one"
                    , "session"
                    , season
                    , String.fromInt eventId
                    , String.fromInt sessionId
                    ]

                FormulaE Nothing ->
                    [ "formula-e" ]

                FormulaE (Just season) ->
                    [ "formula-e", "season", season ]

                FormulaEEvent season eventId ->
                    [ "formula-e", "event", season, String.fromInt eventId ]

                Profile ->
                    [ "profile" ]

                NotFound ->
                    [ "not-found" ]
    in
    Url.Builder.absolute (appPrefix :: parts) []
