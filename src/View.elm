module View exposing (application)

import Browser
import Components.Navbar
import Html exposing (Html)
import Html.Attributes as Attributes
import Model exposing (Model)
import Msg exposing (Msg)


application : Model key -> Browser.Document Msg
application model =
    let
        contents : List (Html Msg)
        contents =
            [ Html.h1
                []
                [ Html.text "Welcome to Pole Prediction!" ]
            ]

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
