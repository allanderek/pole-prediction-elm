module Helpers.Classes exposing
    ( active
    , boolean
    )

import Html exposing (Attribute)
import Html.Attributes as Attributes


boolean : String -> String -> Bool -> Attribute msg
boolean left right isLeft =
    case isLeft of
        True ->
            Attributes.class left

        False ->
            Attributes.class right


active : Bool -> Attribute msg
active =
    boolean "active" "inactive"
