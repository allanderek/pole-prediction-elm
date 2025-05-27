module Components.EventList exposing (view)

import Components.Time
import Html exposing (Html)
import Html.Attributes as Attributes
import Route exposing (Route)
import Time


type alias Config a =
    { toRoute : a -> Route
    , toName : a -> String
    , toStartTime : a -> Time.Posix
    }


view : Time.Zone -> Config event -> List event -> Html msg
view timeZone config events =
    let
        viewEvent : event -> Html msg
        viewEvent event =
            Html.li
                []
                [ Html.a
                    [ Attributes.class "event-link"
                    , config.toRoute event
                        |> Route.href
                    ]
                    [ config.toName event
                        |> Html.text
                    , Html.text " - "
                    , config.toStartTime event
                        |> Components.Time.shortFormat timeZone
                    ]
                ]
    in
    Html.ul
        [ Attributes.class "events-list" ]
        (List.map viewEvent events)
