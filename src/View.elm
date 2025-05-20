module View exposing (application)

import Browser
import Components.Leaderboard
import Components.Login
import Components.Navbar
import Components.UserName
import Dict
import Helpers.Classes
import Helpers.Http
import Helpers.List
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events
import Model exposing (Model)
import Msg exposing (Msg)
import Pages.FormulaOneSession
import Route
import Types.FormulaE
import Types.FormulaOne
import Types.Leaderboard exposing (Leaderboard)


application : Model key -> Browser.Document Msg
application model =
    let
        contents : List (Html Msg)
        contents =
            case model.route of
                Route.Home ->
                    [ Html.h1
                        []
                        [ Html.text "Welcome to Pole Prediction!" ]
                    ]

                Route.Login ->
                    [ Html.h1
                        []
                        [ Html.text "Login" ]
                    , Components.Login.view model.loginForm
                    ]

                Route.FormulaOne mSeason ->
                    let
                        season : Types.FormulaOne.Season
                        season =
                            mSeason
                                |> Maybe.withDefault Types.FormulaOne.currentSeason

                        leaderboardStatus : Helpers.Http.Status Leaderboard
                        leaderboardStatus =
                            Dict.get season model.formulaOneLeaderboards
                                |> Maybe.withDefault Helpers.Http.Ready

                        seasonLeaderboardStatus : Helpers.Http.Status Types.FormulaOne.SeasonLeaderboard
                        seasonLeaderboardStatus =
                            Dict.get season model.formulaOneSeasonLeaderboards
                                |> Maybe.withDefault Helpers.Http.Ready

                        constructorStandingsStatus : Helpers.Http.Status Leaderboard
                        constructorStandingsStatus =
                            Dict.get season model.formulaOneConstructorStandings
                                |> Maybe.withDefault Helpers.Http.Ready

                        driverStandingsStatus : Helpers.Http.Status Leaderboard
                        driverStandingsStatus =
                            Dict.get season model.formulaOneDriverStandings
                                |> Maybe.withDefault Helpers.Http.Ready

                        eventsStatus : Helpers.Http.Status (List Types.FormulaOne.Event)
                        eventsStatus =
                            Dict.get season model.formulaOneEvents
                                |> Maybe.withDefault Helpers.Http.Ready

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
                    , Html.h2 [] [ Html.text "Leaderboard" ]
                    , case leaderboardStatus of
                        Helpers.Http.Inflight ->
                            Html.text "Loading..."

                        Helpers.Http.Ready ->
                            Html.text "Ready"

                        Helpers.Http.Failed _ ->
                            Html.text "Error obtaining the leaderboard"

                        Helpers.Http.Succeeded leaderboard ->
                            Components.Leaderboard.view { firstColumn = "User" } leaderboard
                    , Html.h2 [] [ Html.text "Driver standings" ]
                    , case driverStandingsStatus of
                        Helpers.Http.Inflight ->
                            Html.text "Loading..."

                        Helpers.Http.Ready ->
                            Html.text "Ready"

                        Helpers.Http.Failed _ ->
                            Html.text "Error obtaining the driver standings"

                        Helpers.Http.Succeeded driverStandings ->
                            Components.Leaderboard.view { firstColumn = "Driver" } driverStandings
                    , Html.h2 [] [ Html.text "Constructor standings" ]
                    , case constructorStandingsStatus of
                        Helpers.Http.Inflight ->
                            Html.text "Loading..."

                        Helpers.Http.Ready ->
                            Html.text "Ready"

                        Helpers.Http.Failed _ ->
                            Html.text "Error obtaining the constructor standings"

                        Helpers.Http.Succeeded constructorStandings ->
                            Components.Leaderboard.view { firstColumn = "Constructor" } constructorStandings
                    , Html.h2 [] [ Html.text "Season Leaderboard" ]
                    , case seasonLeaderboardStatus of
                        Helpers.Http.Inflight ->
                            Html.text "Loading..."

                        Helpers.Http.Ready ->
                            Html.text "Ready"

                        Helpers.Http.Failed _ ->
                            Html.text "Error obtaining the season leaderboard"

                        Helpers.Http.Succeeded seasonLeaderboard ->
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
                    , Html.h2 [] [ Html.text "Events" ]
                    , case eventsStatus of
                        Helpers.Http.Inflight ->
                            Html.text "Loading..."

                        Helpers.Http.Ready ->
                            Html.text "Ready"

                        Helpers.Http.Failed _ ->
                            Html.text "Error obtaining the events"

                        Helpers.Http.Succeeded events ->
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
                    ]

                Route.FormulaOneEvent season eventId ->
                    let
                        sessionsStatus : Helpers.Http.Status (List Types.FormulaOne.Session)
                        sessionsStatus =
                            Dict.get eventId model.formulaOneSessions
                                |> Maybe.withDefault Helpers.Http.Ready
                    in
                    [ Html.h1
                        []
                        [ Html.text "Formula One Event" ]
                    , case sessionsStatus of
                        Helpers.Http.Inflight ->
                            Html.text "Loading..."

                        Helpers.Http.Ready ->
                            Html.text "Ready"

                        Helpers.Http.Failed _ ->
                            Html.text "Error obtaining the sessions"

                        Helpers.Http.Succeeded sessions ->
                            let
                                viewSession : Types.FormulaOne.Session -> Html Msg
                                viewSession session =
                                    Html.li
                                        []
                                        [ Html.a
                                            [ Attributes.class "session-link"
                                            , Route.FormulaOneSession season eventId session.id
                                                |> Route.href
                                            ]
                                            [ Html.text session.name ]
                                        ]
                            in
                            Html.ul
                                []
                                (List.map viewSession sessions)
                    ]

                Route.FormulaOneSession _ eventId sessionId ->
                    let
                        mSession : Maybe Types.FormulaOne.Session
                        mSession =
                            Dict.get eventId model.formulaOneSessions
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
                                |> Maybe.andThen (Helpers.List.findWith sessionId .id)
                    in
                    case mSession of
                        Nothing ->
                            [ Html.text "Session not found" ]

                        Just session ->
                            Pages.FormulaOneSession.view model session

                Route.FormulaE mSeason ->
                    let
                        season : Types.FormulaE.Season
                        season =
                            mSeason
                                |> Maybe.withDefault Types.FormulaE.currentSeason

                        leaderboardStatus : Helpers.Http.Status Leaderboard
                        leaderboardStatus =
                            Dict.get season model.formulaELeaderboards
                                |> Maybe.withDefault Helpers.Http.Ready

                        viewLink : Types.FormulaE.Season -> Html Msg
                        viewLink linkSeason =
                            let
                                seasonArg : Maybe Types.FormulaE.Season
                                seasonArg =
                                    case linkSeason == Types.FormulaE.currentSeason of
                                        True ->
                                            Nothing

                                        False ->
                                            Just linkSeason
                            in
                            Html.li
                                [ Helpers.Classes.active (linkSeason == season) ]
                                [ Html.a
                                    [ Attributes.class "season-link"
                                    , Route.href (Route.FormulaE seasonArg)
                                    ]
                                    [ Html.text linkSeason ]
                                ]

                        eventsStatus : Helpers.Http.Status (List Types.FormulaE.Event)
                        eventsStatus =
                            Dict.get season model.formulaEEvents
                                |> Maybe.withDefault Helpers.Http.Ready
                    in
                    [ Html.h1
                        []
                        [ Html.text "Formula E "
                        , Html.text season
                        ]
                    , Html.nav
                        []
                        [ Html.ul
                            []
                            (List.map viewLink [ "2024-25", "2023-24", "2022-23" ])
                        ]
                    , case leaderboardStatus of
                        Helpers.Http.Inflight ->
                            Html.text "Loading..."

                        Helpers.Http.Ready ->
                            Html.text "Ready"

                        Helpers.Http.Failed _ ->
                            Html.text "Error obtaining the leaderboard"

                        Helpers.Http.Succeeded leaderboard ->
                            Components.Leaderboard.view { firstColumn = "User" } leaderboard
                    , case eventsStatus of
                        Helpers.Http.Inflight ->
                            Html.text "Loading..."

                        Helpers.Http.Ready ->
                            Html.text "Ready"

                        Helpers.Http.Failed _ ->
                            Html.text "Error obtaining the events"

                        Helpers.Http.Succeeded events ->
                            let
                                viewEvent : Types.FormulaE.Event -> Html Msg
                                viewEvent event =
                                    Html.li
                                        []
                                        [ Html.a
                                            [ Attributes.class "event-link"
                                            , Route.FormulaEEvent season event.id
                                                |> Route.href
                                            ]
                                            [ Html.text event.name ]
                                        ]
                            in
                            Html.ul
                                []
                                (List.map viewEvent events)
                    ]

                Route.FormulaEEvent season eventId ->
                    [ Html.text "Formula E event not yet done" ]

                Route.Profile ->
                    [ Html.h1
                        []
                        [ Html.text "Profile Page" ]
                    , case Helpers.Http.toMaybe model.userStatus of
                        Just user ->
                            Html.dl
                                []
                                [ Html.dt
                                    []
                                    [ Html.text "Username" ]
                                , Html.dd
                                    []
                                    [ Html.text user.username ]
                                , Html.dt
                                    []
                                    [ Html.text "Name" ]
                                , Html.dd
                                    []
                                    [ Html.text user.fullname ]
                                , Html.dt
                                    []
                                    [ Html.text "Logout" ]
                                , Html.dd
                                    []
                                    [ Html.button
                                        [ Attributes.class "logout-button"
                                        , Html.Events.onClick Msg.Logout
                                        ]
                                        [ Html.text "Logout" ]
                                    ]
                                ]

                        Nothing ->
                            Components.Login.view model.loginForm
                    ]

                Route.NotFound ->
                    [ Html.text "Page not found" ]

        mainElement : Html Msg
        mainElement =
            Html.node "main"
                [ Attributes.class "main-page" ]
                contents
    in
    { title = "Pole prediction"
    , body =
        [ Html.div
            [ Attributes.class "app" ]
            [ Components.Navbar.view model
            , mainElement
            ]
        ]
    }
