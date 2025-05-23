module Helpers.Events exposing
    ( onClickOrDisabled
    , onInputOrDisabled
    )

import Html
import Html.Attributes
import Html.Events


onClickOrDisabled : Bool -> msg -> Html.Attribute msg
onClickOrDisabled disabled msg =
    case disabled of
        True ->
            Html.Attributes.disabled True

        False ->
            Html.Events.onClick msg


onInputOrDisabled : Bool -> (String -> msg) -> Html.Attribute msg
onInputOrDisabled disabled onInput =
    case disabled of
        True ->
            Html.Attributes.disabled True

        False ->
            Html.Events.onInput onInput
