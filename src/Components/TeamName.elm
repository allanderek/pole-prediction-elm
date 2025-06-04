module Components.TeamName exposing (view)

import Html exposing (Html)
import Html.Attributes


type alias Config =
    { name : String
    , class : String
    , primary : String
    , secondary : String
    }


view : Config -> Html msg
view config =
    let
        teamColor : String
        teamColor =
            case config.primary == "#FFFFFF" of
                False ->
                    config.primary

                True ->
                    config.secondary
    in
    Html.span
        [ Html.Attributes.class config.class
        , Html.Attributes.style "color" teamColor
        ]
        [ Html.text config.name ]
