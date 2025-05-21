module Helpers.Attributes exposing (label)

import Html
import Html.Attributes as Attributes


label : String -> Html.Attribute msg
label =
    Attributes.attribute "label"
