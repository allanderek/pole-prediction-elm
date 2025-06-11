module Components.Login exposing
    ( view
    , youMustBeLoggedInTo
    )

import Helpers.Html
import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events
import Model exposing (Model)
import Msg exposing (Msg)
import Route


view : Model key -> Html Msg
view model =
    -- TODO: This should be disabled if the request is inflight
    let
        disabled : Bool
        disabled =
            Helpers.Http.isInflight model.userStatus
    in
    Html.form
        [ Html.Events.onSubmit Msg.LoginSubmit
        , Attributes.disabled disabled
        , Attributes.class "login-form"
        ]
        [ Html.label
            [ Attributes.class "form-label" ]
            [ Html.text "Username"
            , Html.input
                [ Attributes.type_ "text"
                , Attributes.value model.loginForm.username
                , Attributes.name "username"
                , Html.Events.onInput Msg.LoginIdentityInput
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
                , Attributes.value model.loginForm.password
                , Attributes.name "password"
                , Attributes.disabled disabled
                , Html.Events.onInput Msg.LoginPasswordInput
                ]
                []
            ]
        , Html.button
            [ Attributes.type_ "submit"
            , Attributes.name "submit"
            , Attributes.value "submit"
            , Attributes.disabled disabled
            ]
            [ Html.text "Submit" ]
        ]


youMustBeLoggedInTo : String -> Html msg
youMustBeLoggedInTo actionDesc =
    Html.span
        []
        [ Html.text "You must be"
        , Helpers.Html.nbsp
        , Html.a
            [ Route.href Route.Login ]
            [ Html.text "logged in" ]
        , Helpers.Html.nbsp
        , Html.text actionDesc
        ]
