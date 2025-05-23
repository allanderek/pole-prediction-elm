module Components.Time exposing (longFormat)

import Helpers.Html
import Html exposing (Html)
import Html.Attributes as Attributes
import Iso8601
import Time


longFormat : Time.Zone -> Time.Posix -> Html msg
longFormat zone time =
    Html.time
        [ Attributes.datetime (Iso8601.fromTime time)
        , Attributes.class "time"
        ]
        [ Time.toDay zone time
            |> String.fromInt
            |> Html.text
        , Helpers.Html.nbsp
        , Time.toMonth zone time
            |> monthToString
            |> Html.text
        , Helpers.Html.nbsp
        , Time.toYear zone time
            |> String.fromInt
            |> String.padLeft 4 '0'
            |> Html.text
        , Html.text ", "
        , Time.toHour zone time
            |> String.fromInt
            |> String.padLeft 2 '0'
            |> Html.text
        , Html.text ":"
        , Time.toMinute zone time
            |> String.fromInt
            |> String.padLeft 2 '0'
            |> Html.text
        ]


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "Febrary"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"
