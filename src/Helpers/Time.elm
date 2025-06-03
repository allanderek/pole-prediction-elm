module Helpers.Time exposing
    ( datePassed
    , dateReached
    , isEarlier
    )

import Time


isEarlier : Time.Posix -> Time.Posix -> Bool
isEarlier a b =
    Time.posixToMillis a < Time.posixToMillis b


orderByDate : Time.Zone -> Time.Posix -> Time.Posix -> Order
orderByDate zone a b =
    let
        compareBy : (Time.Zone -> Time.Posix -> comparable) -> Order
        compareBy getValue =
            compare (getValue zone a) (getValue zone b)
    in
    case compareBy Time.toYear of
        GT ->
            GT

        LT ->
            LT

        EQ ->
            case compareBy getMonthInt of
                GT ->
                    GT

                LT ->
                    LT

                EQ ->
                    compareBy Time.toDay


dateReached : { a | zone : Time.Zone, now : Time.Posix } -> Time.Posix -> Bool
dateReached model startTime =
    case orderByDate model.zone model.now startTime of
        LT ->
            False

        EQ ->
            True

        GT ->
            True


datePassed : { a | zone : Time.Zone, now : Time.Posix } -> Time.Posix -> Bool
datePassed model startTime =
    case orderByDate model.zone model.now startTime of
        LT ->
            False

        EQ ->
            False

        GT ->
            True


getMonthInt : Time.Zone -> Time.Posix -> Int
getMonthInt zone time =
    case Time.toMonth zone time of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12
