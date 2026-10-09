module Route exposing
    ( Route(..)
    , canonical
    , formulaESeason
    , formulaOneSeason
    , googleOAuthPath
    , href
    , parse
    , unparse
    )

import Html
import Html.Attributes
import Types.FormulaE
import Types.FormulaOne
import Types.OverUnder
import Url
import Url.Builder
import Url.Parser as Parser exposing ((</>))


type Route
    = Home
    | Login
    | Register
    | FormulaOne (Maybe Types.FormulaOne.Season)
    | FormulaOneEvent Types.FormulaOne.Season Types.FormulaOne.EventId
    | FormulaOneSession Types.FormulaOne.Season Types.FormulaOne.EventId Types.FormulaOne.SessionId
    | FormulaE (Maybe Types.FormulaE.Season)
    | FormulaEEvent Types.FormulaE.Season Types.FormulaE.EventId
    | OverUnder
    | OverUnderCompetition Types.OverUnder.CompetitionId
    | Profile
    | NotFound


appPrefix : String
appPrefix =
    "app"


googleOAuthPath : String
googleOAuthPath =
    "/api/auth/google/login"


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
                            , Parser.s "over-under" |> Parser.map OverUnder
                            , Parser.s "over-under"
                                </> Parser.s "competition"
                                </> Parser.int
                                |> Parser.map OverUnderCompetition
                            , Parser.s "login" |> Parser.map Login
                            , Parser.s "register" |> Parser.map Register
                            , Parser.s "profile" |> Parser.map Profile
                            ]
                ]
    in
    url
        |> Parser.parse routeParser
        |> Maybe.withDefault NotFound


{-| The canonical form of a route: the one URL we want search engines to index
for the content it shows. The season-less routes `FormulaOne Nothing` and
`FormulaE Nothing` are aliases for the current season, so they canonicalise to
the explicit season route, which goes on meaning the same thing after the
season rolls over. Every other route is its own canonical form.
-}
canonical : Route -> Route
canonical route =
    case route of
        FormulaOne Nothing ->
            FormulaOne (Just Types.FormulaOne.currentSeason)

        FormulaE Nothing ->
            FormulaE (Just Types.FormulaE.currentSeason)

        _ ->
            route


{-| Internal links always use the explicit season, so that they match the
canonical URL, see `canonical`.
-}
formulaESeason : Types.FormulaE.Season -> Route
formulaESeason season =
    FormulaE (Just season)


formulaOneSeason : Types.FormulaOne.Season -> Route
formulaOneSeason season =
    FormulaOne (Just season)


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

                Register ->
                    [ "register" ]

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

                OverUnder ->
                    [ "over-under" ]

                OverUnderCompetition competitionId ->
                    [ "over-under", "competition", String.fromInt competitionId ]

                Profile ->
                    [ "profile" ]

                NotFound ->
                    [ "not-found" ]
    in
    Url.Builder.absolute (appPrefix :: parts) []
