module Components.Info exposing (view)

import Components.Section
import Html exposing (Html)
import Html.Attributes


type alias Item msg =
    { class : String
    , content : Html msg
    }


view : Components.Section.Config -> List (Item msg) -> Html msg
view config items =
    let
        viewItem : Item msg -> Html msg
        viewItem item =
            Html.p
                [ Html.Attributes.class item.class ]
                [ item.content ]
    in
    Components.Section.view config
        (List.map viewItem items)
