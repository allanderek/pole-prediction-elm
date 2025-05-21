module Helpers.Events exposing (onInputOrDisabled)

import Html
import Html.Attributes
import Html.Events


onInputOrDisabled : Bool -> (String -> msg) -> Html.Attribute msg
onInputOrDisabled disabled onInput =
    case disabled of
        True ->
            Html.Attributes.disabled True

        False ->
            Html.Events.onInput onInput
