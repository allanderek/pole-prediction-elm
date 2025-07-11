module Components.Time exposing
    ( longFormat
    , shortFormat
    )

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


shortFormat : Time.Zone -> Time.Posix -> Html msg
shortFormat zone time =
    let
        dayString : String
        dayString =
            Time.toDay zone time
                |> String.fromInt
    in
    Html.time
        [ Attributes.datetime (Iso8601.fromTime time)
        , Attributes.class "time"
        ]
        [ Html.text dayString
        , Html.sup [] [ ordinalSuffix dayString |> Html.text ]
        , Helpers.Html.nbsp
        , Time.toMonth zone time
            |> monthToShortString
            |> Html.text
        , Helpers.Html.nbsp
        , Time.toYear zone time
            |> String.fromInt
            |> String.padLeft 4 '0'
            |> String.dropLeft 2
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


ordinalSuffix : String -> String
ordinalSuffix numberString =
    let
        suffix : String
        suffix =
            case numberString of
                "11" ->
                    "th"

                "12" ->
                    "th"

                "13" ->
                    "th"

                _ ->
                    case String.right 1 numberString of
                        "1" ->
                            "st"

                        "2" ->
                            "nd"

                        "3" ->
                            "rd"

                        "4" ->
                            "th"

                        "5" ->
                            "th"

                        "6" ->
                            "th"

                        "7" ->
                            "th"

                        "8" ->
                            "th"

                        "9" ->
                            "th"

                        "0" ->
                            "th"

                        _ ->
                            ""
    in
    suffix


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


monthToShortString : Time.Month -> String
monthToShortString month =
    case month of
        Time.Jan ->
            "Jan"

        Time.Feb ->
            "Feb"

        Time.Mar ->
            "Mar"

        Time.Apr ->
            "Apr"

        Time.May ->
            "May"

        Time.Jun ->
            "Jun"

        Time.Jul ->
            "Jul"

        Time.Aug ->
            "Aug"

        Time.Sep ->
            "Sep"

        Time.Oct ->
            "Oct"

        Time.Nov ->
            "Nov"

        Time.Dec ->
            "Dec"
