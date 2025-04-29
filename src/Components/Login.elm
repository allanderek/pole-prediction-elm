module Components.Login exposing (view)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events
import Msg exposing (Msg)
import Types.Login


view : Types.Login.Form -> Html Msg
view form =
    Html.form
        [ Html.Events.onSubmit Msg.LoginSubmit ]
        [ Html.label
            [ Attributes.class "form-label" ]
            [ Html.text "Username"
            , Html.input
                [ Attributes.type_ "text"
                , Attributes.value form.identity
                , Html.Events.onInput Msg.LoginIdentityInput
                , Attributes.placeholder "username"
                ]
                []
            ]
        , Html.label
            [ Attributes.class "form-label" ]
            [ Html.text "Password"
            , Html.input
                [ Attributes.type_ "password"
                , Attributes.value form.password
                , Html.Events.onInput Msg.LoginPasswordInput
                ]
                []
            ]
        , Html.button
            [ Attributes.type_ "submit" ]
            [ Html.text "Submit" ]
        ]
