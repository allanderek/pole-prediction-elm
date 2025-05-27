module Pages.FormulaOneSeason exposing (view)

import Components.EventList
import Components.HttpStatus
import Components.Leaderboard
import Components.SeasonNav
import Components.Section
import Components.UserName
import Dict
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
        seasonNav : Html msg
        seasonNav =
            Components.SeasonNav.view
                { currentSeason = Types.FormulaOne.currentSeason
                , viewedSeason = season
                , allSeasons = [ "2025", "2024" ]
                , toRoute = Route.FormulaOne << Just
                , toName = identity
                }

        eventsSection : Html Msg
        eventsSection =
            let
                eventsStatus : Helpers.Http.Status (List Types.FormulaOne.Event)
                eventsStatus =
                    Dict.get season model.formulaOneEvents
                        |> Maybe.withDefault Helpers.Http.Ready

                content : List (Html Msg)
                content =
                    [ Components.HttpStatus.view
                        { viewFn =
                            Components.EventList.view model
                                { toRoute = Route.FormulaOneEvent season << .id
                                , toName = Types.FormulaOne.eventName
                                , toStartTime = .startTime
                                }
                        , failedMessage = "Error obtaining the events"
                        }
                        eventsStatus
                    ]
            in
            Components.Section.view { title = "Events", class = "formula-one-events" } content

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
            Components.Section.view { title = "Leaderboard", class = "formula-one-leaderboard" } content

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
            Components.Section.view { title = "Driver Standings", class = "formula-one-driver-standings" } content

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
            Components.Section.view { title = "Constructor Standings", class = "formula-one-constructor-standings" } content

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
            Components.Section.view { title = "Season Leaderboard", class = "formula-one-season-leaderboard" } content
    in
    [ Html.h1
        []
        [ Html.text "Formula One "
        , Html.text season
        ]
    , seasonNav
    , eventsSection
    , leaderboardSection
    , driverStandingsSection
    , constructorStandingsSection
    , seasonLeaderboardSection
    ]
