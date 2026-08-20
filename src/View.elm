module View exposing (application)

import Browser
import Components.EventList
import Components.FormulaOneEventInfo
import Components.HttpStatus
import Components.Leaderboard
import Components.Login
import Components.Navbar
import Components.SeasonNav
import Components.Section
import Components.Time
import Dict
import Helpers.Http
import Helpers.List
import Html exposing (Html)
import Html.Attributes as Attributes
import Model exposing (Model)
import Msg exposing (Msg)
import Pages.FormulaEEvent
import Pages.FormulaOneSeason
import Pages.FormulaOneSession
import Pages.OverUnder
import Pages.Profile
import Pages.Register
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
                        , Components.Login.view model
                        ]
                    }

                Route.Register ->
                    { class = "register-page"
                    , contents = Pages.Register.view model
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
                        sortedEvents : List Types.FormulaOne.Event
                        sortedEvents =
                            Model.getFromStatusDict season model.formulaOneEvents
                                |> Maybe.withDefault []
                                |> List.sortBy .round

                        mEvent : Maybe Types.FormulaOne.Event
                        mEvent =
                            Helpers.List.findWith eventId .id sortedEvents

                        eventNav : { prev : Maybe Types.FormulaOne.Event, next : Maybe Types.FormulaOne.Event }
                        eventNav =
                            Helpers.List.findPrevNext (\e -> e.id == eventId) sortedEvents

                        viewPrevButton : Maybe Types.FormulaOne.Event -> Html msg
                        viewPrevButton mItem =
                            case mItem of
                                Nothing ->
                                    Html.span
                                        [ Attributes.class "page-nav-button page-nav-disabled" ]
                                        [ Html.text "←" ]

                                Just event ->
                                    Html.a
                                        [ Attributes.class "page-nav-button"
                                        , Route.FormulaOneEvent season event.id |> Route.href
                                        ]
                                        [ Html.text ("← " ++ Types.FormulaOne.eventName event) ]

                        viewNextButton : Maybe Types.FormulaOne.Event -> Html msg
                        viewNextButton mItem =
                            case mItem of
                                Nothing ->
                                    Html.span
                                        [ Attributes.class "page-nav-button page-nav-disabled" ]
                                        [ Html.text "→" ]

                                Just event ->
                                    Html.a
                                        [ Attributes.class "page-nav-button"
                                        , Route.FormulaOneEvent season event.id |> Route.href
                                        ]
                                        [ Html.text (Types.FormulaOne.eventName event ++ " →") ]

                        eventNavigation : Html msg
                        eventNavigation =
                            Html.nav
                                [ Attributes.class "page-navigation" ]
                                [ Html.div
                                    [ Attributes.class "page-nav-row" ]
                                    [ viewPrevButton eventNav.prev
                                    , viewNextButton eventNav.next
                                    ]
                                ]

                        info : Html msg
                        info =
                            case mEvent of
                                Just event ->
                                    Components.FormulaOneEventInfo.view
                                        model
                                        { title = Types.FormulaOne.eventName event
                                        , class = "formula-one-event-info"
                                        , season = season
                                        , start =
                                            [ { class = "event-start-time"
                                              , content = Components.Time.longFormat model.zone event.startTime
                                              }
                                            ]
                                                ++ (if event.cancelled then
                                                        [ { class = "event-cancelled"
                                                          , content = Html.text "This event has been cancelled."
                                                          }
                                                        ]

                                                    else
                                                        []
                                                   )
                                        , eventId = eventId
                                        , mEvent = mEvent
                                        , mSessionId = Nothing
                                        }

                                Nothing ->
                                    Html.text "Event not found"
                    in
                    { class = "formula-one-event-page"
                    , contents = [ eventNavigation, info ]
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
                                , allSeasons = Types.FormulaE.allSeasons
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
                                        Components.EventList.view model
                                            { toRoute = Route.FormulaEEvent season << .id
                                            , toName = .name
                                            , toStartTime = .startTime
                                            , toEndDate = .startTime
                                            , toCancelled = .cancelled
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
                        sortedFormulaEEvents : List Types.FormulaE.Event
                        sortedFormulaEEvents =
                            Dict.get season model.formulaEEvents
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
                                |> Maybe.withDefault []
                                |> List.sortBy .round

                        mEvent : Maybe Types.FormulaE.Event
                        mEvent =
                            Helpers.List.findWith eventId .id sortedFormulaEEvents

                        formulaEEventNav : { prev : Maybe Types.FormulaE.Event, next : Maybe Types.FormulaE.Event }
                        formulaEEventNav =
                            Helpers.List.findPrevNext (\e -> e.id == eventId) sortedFormulaEEvents

                        viewFormulaEPrevButton : Maybe Types.FormulaE.Event -> Html msg
                        viewFormulaEPrevButton mItem =
                            case mItem of
                                Nothing ->
                                    Html.span
                                        [ Attributes.class "page-nav-button page-nav-disabled" ]
                                        [ Html.text "←" ]

                                Just event ->
                                    Html.a
                                        [ Attributes.class "page-nav-button"
                                        , Route.FormulaEEvent season event.id |> Route.href
                                        ]
                                        [ Html.text ("← " ++ event.name) ]

                        viewFormulaENextButton : Maybe Types.FormulaE.Event -> Html msg
                        viewFormulaENextButton mItem =
                            case mItem of
                                Nothing ->
                                    Html.span
                                        [ Attributes.class "page-nav-button page-nav-disabled" ]
                                        [ Html.text "→" ]

                                Just event ->
                                    Html.a
                                        [ Attributes.class "page-nav-button"
                                        , Route.FormulaEEvent season event.id |> Route.href
                                        ]
                                        [ Html.text (event.name ++ " →") ]

                        formulaEEventNavigation : Html msg
                        formulaEEventNavigation =
                            Html.nav
                                [ Attributes.class "page-navigation" ]
                                [ Html.div
                                    [ Attributes.class "page-nav-row" ]
                                    [ viewFormulaEPrevButton formulaEEventNav.prev
                                    , viewFormulaENextButton formulaEEventNav.next
                                    ]
                                ]
                    in
                    { class = "formula-e-event-page"
                    , contents =
                        case mEvent of
                            Nothing ->
                                [ Html.text "Event not found" ]

                            Just event ->
                                formulaEEventNavigation :: Pages.FormulaEEvent.view model season event
                    }

                Route.OverUnder ->
                    { class = "over-under-page"
                    , contents = Pages.OverUnder.viewCompetitionList model
                    }

                Route.OverUnderCompetition competitionId ->
                    { class = "over-under-competition-page"
                    , contents = Pages.OverUnder.viewCompetition model competitionId
                    }

                Route.Profile ->
                    { class = "profile-page"
                    , contents = Pages.Profile.view model
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
