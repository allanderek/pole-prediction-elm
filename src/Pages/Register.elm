module Pages.Register exposing (view)

import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events
import Model exposing (Model)
import Msg exposing (Msg)
import Route


view : Model key -> List (Html Msg)
view model =
    let
        disabled : Bool
        disabled =
            Helpers.Http.isInflight model.userStatus
    in
    [ Html.h1 [] [ Html.text "Register" ]
    , Html.form
        [ Html.Events.onSubmit Msg.RegisterSubmit
        , Attributes.disabled disabled
        , Attributes.class "register-form"
        ]
        [ Html.label
            [ Attributes.class "form-label" ]
            [ Html.text "Username"
            , Html.input
                [ Attributes.type_ "text"
                , Attributes.value model.registerForm.username
                , Attributes.name "username"
                , Html.Events.onInput Msg.RegisterUsernameInput
                , Attributes.placeholder "username"
                , Attributes.disabled disabled
                ]
                []
            ]
        , Html.label
            [ Attributes.class "form-label" ]
            [ Html.text "Password"
            , Html.input
                [ Attributes.type_ "password"
                , Attributes.value model.registerForm.password
                , Attributes.name "password"
                , Html.Events.onInput Msg.RegisterPasswordInput
                , Attributes.disabled disabled
                ]
                []
            ]
        , Html.label
            [ Attributes.class "form-label" ]
            [ Html.text "Display Name (optional)"
            , Html.input
                [ Attributes.type_ "text"
                , Attributes.value model.registerForm.fullName
                , Attributes.name "fullname"
                , Html.Events.onInput Msg.RegisterFullNameInput
                , Attributes.placeholder "Display name"
                , Attributes.disabled disabled
                ]
                []
            ]
        , Html.label
            [ Attributes.class "form-label" ]
            [ Html.text "Email (optional)"
            , Html.input
                [ Attributes.type_ "email"
                , Attributes.value model.registerForm.email
                , Attributes.name "email"
                , Html.Events.onInput Msg.RegisterEmailInput
                , Attributes.placeholder "email@example.com"
                , Attributes.disabled disabled
                ]
                []
            ]
        , Html.button
            [ Attributes.type_ "submit"
            , Attributes.name "submit"
            , Attributes.value "submit"
            , Attributes.disabled disabled
            ]
            [ Html.text "Register" ]
        ]
    , Html.p
        [ Attributes.class "oauth-login" ]
        [ Html.text "Or "
        , Html.a [ Attributes.href Route.googleOAuthPath ] [ Html.text "register / log in with Google" ]
        ]
    , Html.p
        [ Attributes.class "login-link" ]
        [ Html.text "Already have an account? "
        , Html.a [ Route.href Route.Login ] [ Html.text "Log in here." ]
        ]
    ]
