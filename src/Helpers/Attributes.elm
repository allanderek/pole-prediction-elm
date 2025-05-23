module Helpers.Attributes exposing
    ( label
    , role
    )

import Html
import Html.Attributes as Attributes


role : String -> Html.Attribute msg
role =
    Attributes.attribute "role"


label : String -> Html.Attribute msg
label =
    Attributes.attribute "label"
