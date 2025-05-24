module View exposing (application)

import Browser
import Components.FormulaOneSessionList
import Components.HttpStatus
import Components.Info
import Components.Leaderboard
import Components.Login
import Components.Navbar
import Components.Section
import Components.Time
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
                        mEvent : Maybe Types.FormulaOne.Event
                        mEvent =
                            Model.getFromStatusDict season model.formulaOneEvents
                                |> Maybe.andThen (Helpers.List.findWith eventId .id)

                        info : Html msg
                        info =
                            case mEvent of
                                Just event ->
                                    Components.Info.view
                                        (Types.FormulaOne.eventName event)
                                        [ { class = "event-round"
                                          , content =
                                                String.fromInt event.round
                                                    |> String.append "Round: "
                                                    |> Html.text
                                          }
                                        , { class = "event-start-time"
                                          , content = Components.Time.longFormat model.zone event.startTime
                                          }
                                        ]

                                Nothing ->
                                    Html.text "Event not found"
                    in
                    [ info
                    , Components.FormulaOneSessionList.view model eventId Nothing
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

                        seasonNav : Html msg
                        seasonNav =
                            let
                                viewLink : Types.FormulaE.Season -> Html msg
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
                            in
                            Html.nav
                                []
                                [ Html.ul
                                    []
                                    (List.map viewLink [ "2024-25", "2023-24", "2022-23" ])
                                ]

                        leaderboardSection : Html msg
                        leaderboardSection =
                            let
                                leaderboardStatus : Helpers.Http.Status Leaderboard
                                leaderboardStatus =
                                    Dict.get season model.formulaELeaderboards
                                        |> Maybe.withDefault Helpers.Http.Ready
                            in
                            Components.Section.view "Leaderboard"
                                [ Components.HttpStatus.view
                                    { viewFn = Components.Leaderboard.view { firstColumn = "Team" }
                                    , failedMessage = "Error obtaining the leaderboard"
                                    }
                                    leaderboardStatus
                                ]

                        eventsSection : Html msg
                        eventsSection =
                            let
                                eventsStatus : Helpers.Http.Status (List Types.FormulaE.Event)
                                eventsStatus =
                                    Dict.get season model.formulaEEvents
                                        |> Maybe.withDefault Helpers.Http.Ready

                                viewEvent : Types.FormulaE.Event -> Html msg
                                viewEvent event =
                                    Html.li
                                        []
                                        [ Html.a
                                            [ Attributes.class "event-link"
                                            , Route.FormulaEEvent season event.id
                                                |> Route.href
                                            ]
                                            [ Html.text event.name
                                            , Html.text " - "
                                            , Components.Time.shortFormat model.zone event.startTime
                                            ]
                                        ]

                                viewEvents : List Types.FormulaE.Event -> Html msg
                                viewEvents events =
                                    Html.ul
                                        []
                                        (List.map viewEvent events)
                            in
                            Components.Section.view "Events"
                                [ Components.HttpStatus.view
                                    { viewFn = viewEvents
                                    , failedMessage = "Error obtaining the events"
                                    }
                                    eventsStatus
                                ]
                    in
                    [ Html.h1
                        []
                        [ Html.text "Formula E "
                        , Html.text season
                        ]
                    , seasonNav
                    , leaderboardSection
                    , eventsSection
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
