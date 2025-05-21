module Helpers.Html exposing
    ( int
    , nbsp
    , wrapped
    )

import Html exposing (Html)


int : Int -> Html msg
int i =
    String.fromInt i
        |> Html.text


nbsp : Html msg
nbsp =
    Html.text "\u{00A0}"


wrapped : (List (Html.Attribute msg) -> List (Html msg) -> Html msg) -> Html msg -> Html msg
wrapped nodeFun content =
    nodeFun [] [ content ]
