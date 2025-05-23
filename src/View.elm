module View exposing (application)

import Browser
import Components.Leaderboard
import Components.Login
import Components.Navbar
import Dict
import Helpers.Classes
import Helpers.Http
import Helpers.List
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events
import Model exposing (Model)
import Msg exposing (Msg)
import Pages.FormulaEEvent
import Pages.FormulaOneSeason
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
                    in
                    Pages.FormulaOneSeason.view model season

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
                    let
                        mEvent : Maybe Types.FormulaE.Event
                        mEvent =
                            Dict.get season model.formulaEEvents
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
                                |> Maybe.andThen (Helpers.List.findWith eventId .id)
                    in
                    case mEvent of
                        Nothing ->
                            [ Html.text "Event not found" ]

                        Just event ->
                            Pages.FormulaEEvent.view model event

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
