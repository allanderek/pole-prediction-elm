module Components.OverUnderLeaderboard exposing (view)

{-| Like Components.Leaderboard, but each cell shows what the player answered as well as
what it scored. A bare score cannot be read back to an answer, and where a question has
no recorded view its target defaults to 50, so both answers score 50 and the score says
nothing at all.
-}

import Html exposing (Html)
import Html.Attributes as Attributes
import List.Extra
import Types.OverUnder


view : Types.OverUnder.Leaderboard -> Html msg
view leaderboard =
    let
        -- The best score in each column, so the reader can pick out who called it
        -- right. A column everybody got wrong has a maximum of zero and nothing is
        -- marked, which is the honest thing to show.
        maximums : List Int
        maximums =
            let
                getMaximum : Int -> Int
                getMaximum index =
                    let
                        getScore : Types.OverUnder.LeaderboardRow -> Int
                        getScore row =
                            List.Extra.getAt index row.cells
                                |> Maybe.map .score
                                |> Maybe.withDefault 0
                    in
                    List.map getScore leaderboard.rows
                        |> List.maximum
                        |> Maybe.withDefault 0
            in
            List.range 0 (List.length leaderboard.columns - 1)
                |> List.map getMaximum

        viewHeaderCell : String -> Html msg
        viewHeaderCell column =
            Html.th
                []
                [ Html.text column ]

        viewCell : Int -> Types.OverUnder.LeaderboardCell -> Html msg
        viewCell maximum cell =
            case cell.probability of
                Nothing ->
                    Html.td
                        [ Attributes.class "over-under-leaderboard-cell"
                        , Attributes.class "over-under-cell-unanswered"
                        ]
                        [ Html.text "-" ]

                Just probability ->
                    let
                        scoreText : Html msg
                        scoreText =
                            String.fromInt cell.score
                                |> Html.text
                    in
                    Html.td
                        [ Attributes.class "over-under-leaderboard-cell" ]
                        [ Html.span
                            [ Attributes.class "over-under-cell-answer"
                            , Types.OverUnder.answerClass probability |> Attributes.class
                            ]
                            [ Types.OverUnder.answerLabel probability |> Html.text ]
                        , Html.span
                            [ Attributes.class "over-under-cell-score" ]
                            [ case maximum > 0 && cell.score == maximum of
                                False ->
                                    scoreText

                                True ->
                                    Html.b [] [ scoreText ]
                            ]
                        ]

        viewRow : Types.OverUnder.LeaderboardRow -> Html msg
        viewRow row =
            Html.tr
                []
                (Html.td [] [ Html.text row.name ]
                    :: List.map2 viewCell maximums row.cells
                    ++ [ Html.td
                            [ Attributes.class "over-under-leaderboard-total" ]
                            [ String.fromInt row.total |> Html.text ]
                       ]
                )
    in
    -- A competition can have many questions, so the table is wider than a phone. The
    -- wrapper lets it scroll sideways on its own rather than the whole page.
    Html.div
        [ Attributes.class "over-under-leaderboard-scroll" ]
        [ Html.table
            [ Attributes.class "leaderboard"
            , Attributes.class "over-under-leaderboard"
            ]
            [ Html.thead
                []
                [ Html.tr
                    []
                    (List.map viewHeaderCell ("Player" :: leaderboard.columns ++ [ "Total" ]))
                ]
            , Html.tbody
                []
                (List.map viewRow leaderboard.rows)
            ]
        ]
