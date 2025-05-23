module Components.Section exposing (view)

import Html exposing (Html)
import Html.Attributes as Attributes


view : String -> List (Html msg) -> Html msg
view title content =
    Html.section
        [ Attributes.class "section" ]
        [ Html.h2
            []
            [ Html.text title ]
        , Html.div
            [ Attributes.class "content" ]
            content
        ]
