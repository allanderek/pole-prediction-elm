module View exposing (application)

import Browser
import Components.EventList
import Components.FormulaOneSessionList
import Components.HttpStatus
import Components.Info
import Components.Leaderboard
import Components.Login
import Components.Navbar
import Components.SeasonNav
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
        pageDetails : { class : String, contents : List (Html Msg) }
        pageDetails =
            case model.route of
                Route.Home ->
                    { class = "home-page"
                    , contents =
                        [ Html.h1
                            []
                            [ Html.text "Welcome to Pole Prediction!" ]
                        ]
                    }

                Route.Login ->
                    { class = "login-page"
                    , contents =
                        [ Html.h1
                            []
                            [ Html.text "Login" ]
                        , Components.Login.view model.loginForm
                        ]
                    }

                Route.FormulaOne mSeason ->
                    let
                        season : Types.FormulaOne.Season
                        season =
                            mSeason
                                |> Maybe.withDefault Types.FormulaOne.currentSeason
                    in
                    { class = "formula-one-season-page"
                    , contents = Pages.FormulaOneSeason.view model season
                    }

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
                                        { title = Types.FormulaOne.eventName event
                                        , class = "formula-one-event-info"
                                        }
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
                    { class = "formula-one-event-page"
                    , contents =
                        [ info
                        , Components.FormulaOneSessionList.view model eventId Nothing
                        ]
                    }

                Route.FormulaOneSession _ eventId sessionId ->
                    let
                        mSession : Maybe Types.FormulaOne.Session
                        mSession =
                            Dict.get eventId model.formulaOneSessions
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
                                |> Maybe.andThen (Helpers.List.findWith sessionId .id)
                    in
                    { class = "formula-one-session-page"
                    , contents =
                        case mSession of
                            Nothing ->
                                [ Html.text "Session not found" ]

                            Just session ->
                                Pages.FormulaOneSession.view model session
                    }

                Route.FormulaE mSeason ->
                    let
                        season : Types.FormulaE.Season
                        season =
                            mSeason
                                |> Maybe.withDefault Types.FormulaE.currentSeason

                        seasonNav : Html msg
                        seasonNav =
                            Components.SeasonNav.view
                                { currentSeason = Types.FormulaE.currentSeason
                                , viewedSeason = season
                                , allSeasons = [ "2024-25", "2023-24", "2022-23" ]
                                , toRoute = Route.FormulaE << Just
                                , toName = identity
                                }

                        leaderboardSection : Html msg
                        leaderboardSection =
                            let
                                leaderboardStatus : Helpers.Http.Status Leaderboard
                                leaderboardStatus =
                                    Dict.get season model.formulaELeaderboards
                                        |> Maybe.withDefault Helpers.Http.Ready
                            in
                            Components.Section.view
                                { title = "Leaderboard"
                                , class = "formula-e-leaderboard"
                                }
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
                            in
                            Components.Section.view
                                { title = "Events"
                                , class = "formula-e-events"
                                }
                                [ Components.HttpStatus.view
                                    { viewFn =
                                        Components.EventList.view model.zone
                                            { toRoute = Route.FormulaEEvent season << .id
                                            , toName = .name
                                            , toStartTime = .startTime
                                            }
                                    , failedMessage = "Error obtaining the events"
                                    }
                                    eventsStatus
                                ]
                    in
                    { class = "formula-e-season-page"
                    , contents =
                        [ Html.h1
                            []
                            [ Html.text "Formula E "
                            , Html.text season
                            ]
                        , seasonNav
                        , leaderboardSection
                        , eventsSection
                        ]
                    }

                Route.FormulaEEvent season eventId ->
                    let
                        mEvent : Maybe Types.FormulaE.Event
                        mEvent =
                            Dict.get season model.formulaEEvents
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
                                |> Maybe.andThen (Helpers.List.findWith eventId .id)
                    in
                    { class = "formula-e-event-page"
                    , contents =
                        case mEvent of
                            Nothing ->
                                [ Html.text "Event not found" ]

                            Just event ->
                                Pages.FormulaEEvent.view model event
                    }

                Route.Profile ->
                    { class = "profile-page"
                    , contents =
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
                    }

                Route.NotFound ->
                    { class = "not-found-page"
                    , contents = [ Html.text "Page not found" ]
                    }

        mainElement : Html Msg
        mainElement =
            Html.node "main"
                [ Attributes.class "main-page"
                , Attributes.class pageDetails.class
                ]
                pageDetails.contents
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
