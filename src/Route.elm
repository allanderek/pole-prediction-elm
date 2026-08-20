module Route exposing
    ( Route(..)
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


formulaESeason : Types.FormulaE.Season -> Route
formulaESeason season =
    let
        mSeason : Maybe Types.FormulaE.Season
        mSeason =
            case season == Types.FormulaE.currentSeason of
                True ->
                    Nothing

                False ->
                    Just season
    in
    FormulaE mSeason


formulaOneSeason : Types.FormulaOne.Season -> Route
formulaOneSeason season =
    let
        mSeason : Maybe Types.FormulaOne.Season
        mSeason =
            case season == Types.FormulaOne.currentSeason of
                True ->
                    Nothing

                False ->
                    Just season
    in
    FormulaOne mSeason


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
