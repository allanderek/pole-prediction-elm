module View exposing (application)

import Browser
import Components.Login
import Components.Navbar
import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Model exposing (Model)
import Msg exposing (Msg)
import Route


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
