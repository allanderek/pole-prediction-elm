module Components.Navbar exposing (view)

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
                    [ Route.href route ]
                    [ Html.text label ]
                ]

        profileOrLoginLink : Html msg
        profileOrLoginLink =
            case model.mUser of
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
                [ profileOrLoginLink ]
            ]
        ]
