module Pages.FormulaOneSession exposing (view)

import Components.FormulaOneSessionEntry
import Components.UserName
import Dict
import Helpers.Http
import Helpers.List
import Html exposing (Html)
import Html.Attributes as Attributes
import Maybe.Extra
import Model exposing (Model)
import Msg exposing (Msg)
import Types.FormulaOne


view : Model key -> Types.FormulaOne.SessionId -> List (Html Msg)
view model sessionId =
    let
        entrantsStatus : Helpers.Http.Status (List Types.FormulaOne.Entrant)
        entrantsStatus =
            Dict.get sessionId model.formulaOneEntrants
                |> Maybe.withDefault Helpers.Http.Ready

        leaderboardStatus : Helpers.Http.Status Types.FormulaOne.SessionLeaderboard
        leaderboardStatus =
            Dict.get sessionId model.formulaOneSessionLeaderboards
                |> Maybe.withDefault Helpers.Http.Ready

        viewEntrant : Types.FormulaOne.Entrant -> Html Msg
        viewEntrant entrant =
            Html.li
                []
                [ Html.span
                    [ Attributes.class "entrant-number" ]
                    [ Html.text (String.fromInt entrant.number) ]
                , Html.span
                    [ Attributes.class "entrant-driver" ]
                    [ Html.text entrant.driver ]
                , Html.span
                    [ Attributes.class "entrant-team" ]
                    [ Html.text entrant.teamShortName ]
                ]
    in
    [ Html.h1
        []
        [ Html.text "Formula One Session" ]
    , case entrantsStatus of
        Helpers.Http.Inflight ->
            Html.text "Loading..."

        Helpers.Http.Ready ->
            Html.text "Ready"

        Helpers.Http.Failed _ ->
            Html.text "Error obtaining the session entrants"

        Helpers.Http.Succeeded entrants ->
            case Helpers.Http.toMaybe model.userStatus of
                Just user ->
                    -- TODO: Technically here we have to merge the entrants available with the current entry
                    let
                        currentPrediction : List Types.FormulaOne.Entrant
                        currentPrediction =
                            Model.getFormulaOneCurrentSessionPrediction model sessionId
                                |> Maybe.withDefault entrants
                    in
                    Html.div
                        []
                        [ Html.h2
                            []
                            [ Html.text "Sortable for prediction entry" ]
                        , Components.FormulaOneSessionEntry.view
                            { kind = Components.FormulaOneSessionEntry.Prediction
                            , user = user
                            , entrants = currentPrediction
                            , reorderMessage = Msg.ReorderFormulaOneSessionPredictionEntry sessionId
                            , submitMessage =
                                Msg.SubmitFormulaOneSessionEntry sessionId
                                    (List.map .id currentPrediction)
                            }
                        , Html.h2 [] [ Html.text "What the model sees for prediction entry" ]
                        , Html.ol [] (List.map viewEntrant currentPrediction)
                        ]

                Nothing ->
                    Html.ul
                        []
                        (List.map viewEntrant entrants)
    , case entrantsStatus of
        Helpers.Http.Inflight ->
            Html.text "Loading..."

        Helpers.Http.Ready ->
            Html.text "Ready"

        Helpers.Http.Failed _ ->
            Html.text "Error obtaining the session entrants"

        Helpers.Http.Succeeded entrants ->
            case Helpers.Http.toMaybe model.userStatus of
                Nothing ->
                    Html.text "You must be a logged in admin to enter the results."

                Just user ->
                    case user.isAdmin of
                        False ->
                            Html.text "You must be an admin user to enter the results."

                        True ->
                            let
                                currentResults : List Types.FormulaOne.Entrant
                                currentResults =
                                    Model.getFormulaOneCurrentSessionResults model sessionId
                                        |> Maybe.withDefault entrants
                            in
                            Html.div
                                []
                                [ Html.h2 [] [ Html.text "Sortable Results Entry" ]
                                , Components.FormulaOneSessionEntry.view
                                    { kind = Components.FormulaOneSessionEntry.Result
                                    , user = user
                                    , entrants = currentResults
                                    , reorderMessage = Msg.ReorderFormulaOneSessionResultEntry sessionId
                                    , submitMessage =
                                        Msg.SubmitFormulaOneSessionResult sessionId
                                            (List.map .id currentResults)
                                    }
                                , Html.h2 [] [ Html.text "What the model sees for results entry" ]
                                , Html.ol [] (List.map viewEntrant currentResults)
                                ]
    , case leaderboardStatus of
        Helpers.Http.Inflight ->
            Html.text "Loading..."

        Helpers.Http.Ready ->
            Html.text "Ready"

        Helpers.Http.Failed _ ->
            Html.text "Error obtaining the session leaderboard"

        Helpers.Http.Succeeded leaderboard ->
            let
                viewRow : Types.FormulaOne.SessionLeaderboardRow -> Html Msg
                viewRow leaderboardRow =
                    let
                        viewScoredRow : Types.FormulaOne.ScoredPredictionRow -> Html Msg
                        viewScoredRow scoredRow =
                            Html.tr
                                []
                                [ Html.td
                                    [ Attributes.class "scored-row-position" ]
                                    [ Html.text (String.fromInt scoredRow.predictedPosition) ]
                                , Html.td
                                    [ Attributes.class "scored-row-driver" ]
                                    [ Html.text scoredRow.entrant.driver ]
                                , Html.td
                                    [ Attributes.class "scored-row-score" ]
                                    [ Html.text (String.fromInt scoredRow.score) ]
                                ]
                    in
                    Html.li
                        []
                        [ Html.details
                            []
                            [ Html.summary
                                []
                                [ Html.span
                                    [ Attributes.class "user-name" ]
                                    [ Components.UserName.formulaOne
                                        leaderboardRow.userId
                                        leaderboardRow.userName
                                    ]
                                , Html.span
                                    [ Attributes.class "total-score" ]
                                    [ Html.text (String.fromInt leaderboardRow.total) ]
                                ]
                            , Html.table
                                []
                                (List.map viewScoredRow leaderboardRow.rows)
                            ]
                        ]
            in
            Html.ul [] (List.map viewRow leaderboard.predictions)
    ]
