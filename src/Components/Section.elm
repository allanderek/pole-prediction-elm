module Components.Section exposing (view)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Extra


view : String -> List (Html msg) -> Html msg
view titleString content =
    let
        title : Html msg
        title =
            case String.isEmpty titleString of
                True ->
                    Html.Extra.nothing

                False ->
                    Html.h2 [] [ Html.text titleString ]
    in
    Html.section
        [ Attributes.class "section" ]
        (title :: content)
