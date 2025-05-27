module Components.EventList exposing (view)

import Components.Time
import Helpers.Classes
import Helpers.Time
import Html exposing (Html)
import Html.Attributes as Attributes
import Route exposing (Route)
import Time


type alias Config a =
    { toRoute : a -> Route
    , toName : a -> String
    , toStartTime : a -> Time.Posix
    }


view : { a | now : Time.Posix, zone : Time.Zone } -> Config event -> List event -> Html msg
view model config events =
    let
        viewEvent : event -> Html msg
        viewEvent event =
            let
                startTime : Time.Posix
                startTime =
                    config.toStartTime event

                hasFinished : Bool
                hasFinished =
                    case Helpers.Time.orderByDate model.zone startTime model.now of
                        LT ->
                            True

                        EQ ->
                            False

                        GT ->
                            False
            in
            Html.li
                []
                [ Html.a
                    [ Attributes.class "event-link"
                    , config.toRoute event
                        |> Route.href
                    , Helpers.Classes.boolean "finished" "not-finished" hasFinished
                    ]
                    [ config.toName event
                        |> Html.text
                    , Html.text " - "
                    , Components.Time.shortFormat model.zone startTime
                    ]
                ]
    in
    Html.ul
        [ Attributes.class "events-list" ]
        (List.map viewEvent events)
