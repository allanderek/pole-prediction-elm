module Helpers.Html exposing
    ( int
    , nbsp
    )

import Html exposing (Html)


int : Int -> Html msg
int i =
    String.fromInt i
        |> Html.text


nbsp : Html msg
nbsp =
    Html.text "\u{00A0}"
