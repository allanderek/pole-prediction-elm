module Pages.FormulaEEvent exposing (view)

import Html exposing (Html)
import Html.Attributes
import Model exposing (Model)
import Msg exposing (Msg)
import Types.FormulaE


view : Model key -> Types.FormulaE.Event -> List (Html Msg)
view model event =
    let
        info : Html msg
        info =
            Html.div
                [ Html.Attributes.class "formula-e-event" ]
                [ Html.h2
                    [ Html.Attributes.class "event-name" ]
                    [ Html.text event.name ]
                , Html.p
                    [ Html.Attributes.class "event-country" ]
                    [ Html.text event.country ]
                , Html.p
                    [ Html.Attributes.class "event-circuit" ]
                    [ Html.text event.circuit ]

                -- , Html.p
                --     [ Html.Attributes.class "event-date" ]
                --     [ Html.text (Time.toString event.date) ]
                ]
    in
    [ info
    , case event.cancelled of
        True ->
            Html.div
                [ Html.Attributes.class "event-cancelled" ]
                [ Html.text "This event has been cancelled." ]

        False ->
            Html.div
                [ Html.Attributes.class "event-not-cancelled" ]
                [ Html.text "This event is not cancelled." ]
    ]
