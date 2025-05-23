module Pages.FormulaOneSession exposing (view)

import Components.FormulaOneSessionEntry
import Components.HttpStatus
import Components.Login
import Components.Section
import Components.UserName
import Dict
import Helpers.Http
import Helpers.Time
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Extra
import Model exposing (Model)
import Msg exposing (Msg)
import Types.FormulaOne


view : Model key -> Types.FormulaOne.Session -> List (Html Msg)
view model session =
    let
        viewPredictionEntry : List Types.FormulaOne.Entrant -> Html Msg
        viewPredictionEntry entrants =
            case Helpers.Http.toMaybe model.userStatus of
                Just user ->
                    -- TODO: Technically here we have to merge the entrants available with the current entry
                    let
                        currentPrediction : List Types.FormulaOne.Entrant
                        currentPrediction =
                            Model.getFormulaOneCurrentSessionPrediction model session.id
                                |> Maybe.withDefault entrants
                    in
                    Components.Section.view "Prediction entry"
                        [ Components.FormulaOneSessionEntry.view
                            { kind = Components.FormulaOneSessionEntry.Prediction
                            , user = user
                            , entrants = currentPrediction
                            , reorderMessage = Msg.ReorderFormulaOneSessionPredictionEntry session.id
                            , submitMessage =
                                Msg.SubmitFormulaOneSessionEntry session.id
                                    (List.map .id currentPrediction)
                            }
                        ]

                Nothing ->
                    Components.Login.youMustBeLoggedInTo "make a prediction"

        viewResultEntry : List Types.FormulaOne.Entrant -> Html Msg
        viewResultEntry entrants =
            case Helpers.Http.toMaybe model.userStatus of
                Nothing ->
                    Html.Extra.nothing

                Just user ->
                    case user.isAdmin of
                        False ->
                            Html.Extra.nothing

                        True ->
                            let
                                currentResults : List Types.FormulaOne.Entrant
                                currentResults =
                                    Model.getFormulaOneCurrentSessionResults model session.id
                                        |> Maybe.withDefault entrants
                            in
                            Components.Section.view "Results entry"
                                [ Components.FormulaOneSessionEntry.view
                                    { kind = Components.FormulaOneSessionEntry.Result
                                    , user = user
                                    , entrants = currentResults
                                    , reorderMessage = Msg.ReorderFormulaOneSessionResultEntry session.id
                                    , submitMessage =
                                        Msg.SubmitFormulaOneSessionResult session.id
                                            (List.map .id currentResults)
                                    }
                                ]

        entrySection : Html Msg
        entrySection =
            let
                entrantsStatus : Helpers.Http.Status (List Types.FormulaOne.Entrant)
                entrantsStatus =
                    Dict.get session.id model.formulaOneEntrants
                        |> Maybe.withDefault Helpers.Http.Ready

                withEntrants : List Types.FormulaOne.Entrant -> Html Msg
                withEntrants entrants =
                    case Helpers.Time.isEarlier model.now session.startTime of
                        True ->
                            viewPredictionEntry entrants

                        False ->
                            viewResultEntry entrants
            in
            Components.HttpStatus.view
                { viewFn = withEntrants
                , failedMessage = "Error obtaining the details of the session entrants"
                }
                entrantsStatus

        leaderboardSection : Html Msg
        leaderboardSection =
            case Helpers.Time.isEarlier model.now session.startTime of
                True ->
                    Html.Extra.nothing

                False ->
                    let
                        leaderboardStatus : Helpers.Http.Status Types.FormulaOne.SessionLeaderboard
                        leaderboardStatus =
                            Dict.get session.id model.formulaOneSessionLeaderboards
                                |> Maybe.withDefault Helpers.Http.Ready

                        withLeaderboard : Types.FormulaOne.SessionLeaderboard -> Html Msg
                        withLeaderboard leaderboard =
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
                            Components.Section.view "Leaderboard"
                                [ Html.ul [] (List.map viewRow leaderboard.predictions) ]
                    in
                    Components.HttpStatus.view
                        { viewFn = withLeaderboard
                        , failedMessage = "Error obtaining the session leaderboard"
                        }
                        leaderboardStatus
    in
    [ Html.h1 [] [ Html.text "Formula One Session" ]
    , entrySection
    , leaderboardSection
    ]
