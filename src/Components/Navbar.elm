module Components.Navbar exposing (view)

import Helpers.Classes
import Helpers.Http
import Html exposing (Html)
import Model exposing (Model)
import Route exposing (Route)


view : Model key -> Html msg
view model =
    let
        viewLink : String -> Route -> Html msg
        viewLink label route =
            Html.li
                []
                [ Html.a
                    [ Route.href route
                    , Helpers.Classes.active (model.route == route)
                    ]
                    [ Html.text label ]
                ]

        profileOrLoginLink : Html msg
        profileOrLoginLink =
            case Helpers.Http.toMaybe model.userStatus of
                Just user ->
                    viewLink (String.append "Profile: " user.username) Route.Profile

                Nothing ->
                    viewLink "Login" Route.Login
    in
    Html.aside
        []
        [ Html.nav
            []
            [ Html.ul
                []
                [ viewLink "Formula One" (Route.FormulaOne Nothing)
                , viewLink "Formula E" (Route.FormulaE Nothing)
                , profileOrLoginLink
                ]
            ]
        ]
