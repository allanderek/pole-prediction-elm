module Pages.FormulaOneSeason exposing (view)

import Components.HttpStatus
import Components.Leaderboard
import Components.Section
import Components.UserName
import Dict
import Helpers.Classes
import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Model exposing (Model)
import Msg exposing (Msg)
import Route
import Types.FormulaOne
import Types.Leaderboard exposing (Leaderboard)


view : Model key -> Types.FormulaOne.Season -> List (Html Msg)
view model season =
    let
        viewLink : Types.FormulaOne.Season -> Html Msg
        viewLink linkSeason =
            let
                seasonArg : Maybe Types.FormulaOne.Season
                seasonArg =
                    case linkSeason == Types.FormulaOne.currentSeason of
                        True ->
                            Nothing

                        False ->
                            Just linkSeason
            in
            Html.li
                [ Helpers.Classes.active (linkSeason == season) ]
                [ Html.a
                    [ Attributes.class "season-link"
                    , Route.href (Route.FormulaOne seasonArg)
                    ]
                    [ Html.text linkSeason ]
                ]

        eventsSection : Html Msg
        eventsSection =
            let
                eventsStatus : Helpers.Http.Status (List Types.FormulaOne.Event)
                eventsStatus =
                    Dict.get season model.formulaOneEvents
                        |> Maybe.withDefault Helpers.Http.Ready

                content : List (Html Msg)
                content =
                    let
                        viewEvents : List Types.FormulaOne.Event -> Html Msg
                        viewEvents events =
                            let
                                viewEvent : Types.FormulaOne.Event -> Html Msg
                                viewEvent event =
                                    Html.li
                                        []
                                        [ Html.a
                                            [ Attributes.class "event-link"
                                            , Route.FormulaOneEvent season event.id
                                                |> Route.href
                                            ]
                                            [ Html.text event.name ]
                                        ]
                            in
                            Html.ul
                                []
                                (List.map viewEvent events)
                    in
                    [ Components.HttpStatus.view
                        { viewFn = viewEvents
                        , failedMessage = "Error obtaining the events"
                        }
                        eventsStatus
                    ]
            in
            Components.Section.view "Events" content

        leaderboardSection : Html Msg
        leaderboardSection =
            let
                leaderboardStatus : Helpers.Http.Status Leaderboard
                leaderboardStatus =
                    Dict.get season model.formulaOneLeaderboards
                        |> Maybe.withDefault Helpers.Http.Ready

                content : List (Html Msg)
                content =
                    [ Components.HttpStatus.view
                        { viewFn = Components.Leaderboard.view { firstColumn = "User" }
                        , failedMessage = "Error obtaining the leaderboard"
                        }
                        leaderboardStatus
                    ]
            in
            Components.Section.view "Leaderboard" content

        driverStandingsSection : Html Msg
        driverStandingsSection =
            let
                driverStandingsStatus : Helpers.Http.Status Leaderboard
                driverStandingsStatus =
                    Dict.get season model.formulaOneDriverStandings
                        |> Maybe.withDefault Helpers.Http.Ready

                content : List (Html Msg)
                content =
                    [ Components.HttpStatus.view
                        { viewFn = Components.Leaderboard.view { firstColumn = "Driver" }
                        , failedMessage = "Error obtaining the driver standings"
                        }
                        driverStandingsStatus
                    ]
            in
            Components.Section.view "Driver Standings" content

        constructorStandingsSection : Html Msg
        constructorStandingsSection =
            let
                constructorStandingsStatus : Helpers.Http.Status Leaderboard
                constructorStandingsStatus =
                    Dict.get season model.formulaOneConstructorStandings
                        |> Maybe.withDefault Helpers.Http.Ready

                content : List (Html Msg)
                content =
                    [ Components.HttpStatus.view
                        { viewFn = Components.Leaderboard.view { firstColumn = "Constructor" }
                        , failedMessage = "Error obtaining the constructor standings"
                        }
                        constructorStandingsStatus
                    ]
            in
            Components.Section.view "Constructor Standings" content

        seasonLeaderboardSection : Html Msg
        seasonLeaderboardSection =
            let
                seasonLeaderboardStatus : Helpers.Http.Status Types.FormulaOne.SeasonLeaderboard
                seasonLeaderboardStatus =
                    Dict.get season model.formulaOneSeasonLeaderboards
                        |> Maybe.withDefault Helpers.Http.Ready

                content : List (Html Msg)
                content =
                    let
                        viewLeaderboard : Types.FormulaOne.SeasonLeaderboard -> Html Msg
                        viewLeaderboard seasonLeaderboard =
                            let
                                viewRow : Types.FormulaOne.SeasonLeaderboardRow -> Html Msg
                                viewRow leaderboardRow =
                                    let
                                        viewScoredRow : Types.FormulaOne.SeasonPredictionRow -> Html Msg
                                        viewScoredRow scoredRow =
                                            Html.tr
                                                []
                                                [ Html.td
                                                    [ Attributes.class "scored-row-position" ]
                                                    [ Html.text (String.fromInt scoredRow.predictedPosition) ]
                                                , Html.td
                                                    [ Attributes.class "scored-row-driver" ]
                                                    [ Html.text scoredRow.teamName ]
                                                , Html.td
                                                    [ Attributes.class "scored-row-score" ]
                                                    [ Html.text (String.fromInt scoredRow.difference) ]
                                                ]
                                    in
                                    Html.li
                                        []
                                        [ Html.details
                                            []
                                            [ Html.summary
                                                []
                                                [ Html.span
                                                    [ Attributes.class "user-name" ]
                                                    [ Components.UserName.formulaOne
                                                        leaderboardRow.userId
                                                        leaderboardRow.userName
                                                    ]
                                                , Html.span
                                                    [ Attributes.class "total-score" ]
                                                    [ Html.text (String.fromInt leaderboardRow.total) ]
                                                ]
                                            , Html.table
                                                []
                                                (List.map viewScoredRow leaderboardRow.rows)
                                            ]
                                        ]
                            in
                            Html.ul [] (List.map viewRow seasonLeaderboard)
                    in
                    [ Components.HttpStatus.view
                        { viewFn = viewLeaderboard
                        , failedMessage = "Error obtaining the season leaderboard"
                        }
                        seasonLeaderboardStatus
                    ]
            in
            Components.Section.view "Season Leaderboard" content
    in
    [ Html.h1
        []
        [ Html.text "Formula One "
        , Html.text season
        ]
    , Html.nav
        []
        [ Html.ul
            []
            (List.map viewLink [ "2025", "2024" ])
        ]
    , eventsSection
    , leaderboardSection
    , driverStandingsSection
    , constructorStandingsSection
    , seasonLeaderboardSection
    ]
