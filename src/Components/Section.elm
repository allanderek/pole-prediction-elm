module Components.Section exposing
    ( Config
    , view
    )

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Extra


type alias Config =
    { title : String
    , class : String
    }


view : Config -> List (Html msg) -> Html msg
view config content =
    let
        title : Html msg
        title =
            case String.isEmpty config.title of
                True ->
                    Html.Extra.nothing

                False ->
                    Html.h2 [] [ Html.text config.title ]
    in
    Html.section
        [ Attributes.class "section"
        , Attributes.class config.class
        ]
        (title :: content)
