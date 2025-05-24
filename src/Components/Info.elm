module Components.Info exposing (view)

import Components.Section
import Html exposing (Html)
import Html.Attributes


type alias Item msg =
    { class : String
    , content : Html msg
    }


view : String -> List (Item msg) -> Html msg
view title items =
    let
        viewItem : Item msg -> Html msg
        viewItem item =
            Html.p
                [ Html.Attributes.class item.class ]
                [ item.content ]
    in
    Components.Section.view title
        (List.map viewItem items)
