module Components.Leaderboard exposing (view)

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attributes
import List.Extra
import Types.Leaderboard exposing (Leaderboard)


view : Leaderboard -> Html msg
view leaderboard =
    let
        viewHeaderCell : String -> Html msg
        viewHeaderCell column =
            Html.th
                []
                [ Html.text column ]

        maximums : List Int
        maximums =
            let
                getMaximum : Int -> Int
                getMaximum index =
                    let
                        getScore : Types.Leaderboard.LeaderboardRow -> Int
                        getScore row =
                            List.Extra.getAt index row.scores
                                |> Maybe.withDefault 0
                    in
                    List.map getScore leaderboard.rows
                        |> List.maximum
                        |> Maybe.withDefault 0
            in
            List.range 0 (List.length leaderboard.columns - 1)
                |> List.map getMaximum

        viewRow : Types.Leaderboard.LeaderboardRow -> Html msg
        viewRow row =
            let
                viewCell : Int -> Int -> Html msg
                viewCell maximum score =
                    let
                        text : Html msg
                        text =
                            String.fromInt score
                                |> Html.text
                    in
                    Html.td
                        []
                        [ case maximum > 0 && score == maximum of
                            False ->
                                text

                            True ->
                                Html.b [] [ text ]
                        ]

                scoreCells : List (Html msg)
                scoreCells =
                    List.map2 viewCell maximums row.scores

                userCell : Html msg
                userCell =
                    Html.td
                        []
                        [ Html.text row.userName ]
            in
            Html.tr [] (userCell :: scoreCells)
    in
    Html.table
        [ Attributes.class "leaderboard" ]
        [ Html.thead
            []
            [ Html.tr
                []
                (List.map viewHeaderCell ("User" :: leaderboard.columns))
            ]
        , Html.tbody
            []
            (List.map viewRow leaderboard.rows)
        ]
