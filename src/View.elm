module View exposing (application)

import Browser
import Components.Leaderboard
import Components.Login
import Components.Navbar
import Dict
import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events
import Model exposing (Model)
import Msg exposing (Msg)
import Route
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

                Route.FormulaOne ->
                    let
                        leaderboardStatus : Helpers.Http.Status Leaderboard
                        leaderboardStatus =
                            Dict.get Types.FormulaOne.currentSeason model.formulaOneLeaderboards
                                |> Maybe.withDefault Helpers.Http.Ready
                    in
                    [ Html.h1
                        []
                        [ Html.text "Formula One" ]
                    , case leaderboardStatus of
                        Helpers.Http.Inflight ->
                            Html.text "Loading..."

                        Helpers.Http.Ready ->
                            Html.text "Ready"

                        Helpers.Http.Failed _ ->
                            Html.text "Error obtaining the leaderboard"

                        Helpers.Http.Succeeded leaderboard ->
                            Components.Leaderboard.view leaderboard
                    ]

                Route.FormulaE ->
                    [ Html.h1
                        []
                        [ Html.text "Formula E" ]
                    ]

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
