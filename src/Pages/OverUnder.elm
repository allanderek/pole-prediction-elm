module Pages.OverUnder exposing
    ( viewCompetition
    , viewCompetitionList
    )

import Components.HttpStatus
import Components.Section
import Components.Time
import Helpers.Http
import Helpers.List
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Extra
import Model exposing (Model)
import Msg exposing (Msg)
import Route
import Types.OverUnder


viewCompetitionList : Model key -> List (Html Msg)
viewCompetitionList model =
    [ Html.h1
        []
        [ Html.text "Over/Under" ]
    , Components.Section.view
        { title = "Competitions"
        , class = "over-under-competitions"
        }
        [ Components.HttpStatus.view
            { viewFn = viewCompetitionLinks model
            , failedMessage = "Error obtaining the over/under competitions"
            }
            model.overUnderCompetitions
        ]
    ]


viewCompetitionLinks : Model key -> List Types.OverUnder.Competition -> Html Msg
viewCompetitionLinks model competitions =
    case competitions of
        [] ->
            Html.text "There are no over/under competitions yet."

        _ ->
            Html.ul
                [ Attributes.class "over-under-competition-list" ]
                (List.map (viewCompetitionLink model) competitions)


viewCompetitionLink : Model key -> Types.OverUnder.Competition -> Html Msg
viewCompetitionLink model competition =
    Html.li
        [ Attributes.class "over-under-competition-item" ]
        [ Html.a
            [ Route.OverUnderCompetition competition.id |> Route.href ]
            [ Html.text competition.name ]
        , viewDescription competition
        , viewDeadline model competition
        , viewAnsweredCount model competition
        ]


viewCompetition : Model key -> Types.OverUnder.CompetitionId -> List (Html Msg)
viewCompetition model competitionId =
    let
        viewFound : List Types.OverUnder.Competition -> List (Html Msg)
        viewFound competitions =
            case Helpers.List.findWith competitionId .id competitions of
                Nothing ->
                    [ Html.text "Competition not found" ]

                Just competition ->
                    viewCompetitionDetail model competition
    in
    Components.HttpStatus.viewList
        { viewFn = viewFound
        , failedMessage = "Error obtaining the over/under competitions"
        }
        model.overUnderCompetitions


viewCompetitionDetail : Model key -> Types.OverUnder.Competition -> List (Html Msg)
viewCompetitionDetail model competition =
    let
        questionsSection : Html Msg
        questionsSection =
            case Types.OverUnder.deadlinePassed model.now competition of
                False ->
                    Components.Section.view
                        { title = "Questions"
                        , class = "over-under-questions"
                        }
                        [ viewQuestionList model competition ]

                True ->
                    Components.Section.view
                        { title = "Results"
                        , class = "over-under-results"
                        }
                        [ viewQuestionList model competition
                        , Html.p
                            [ Attributes.class "over-under-placeholder" ]
                            [ Html.text "Everyone's answers and their scores will appear here." ]
                        ]
    in
    [ Html.h1
        []
        [ Html.text competition.name ]
    , viewDescription competition
    , viewDeadline model competition
    , questionsSection
    ]


viewQuestionList : Model key -> Types.OverUnder.Competition -> Html Msg
viewQuestionList model competition =
    case competition.questions of
        [] ->
            Html.text "This competition has no questions yet."

        _ ->
            Html.ul
                [ Attributes.class "over-under-question-list" ]
                (List.map (viewQuestion model competition) competition.questions)


viewQuestion : Model key -> Types.OverUnder.Competition -> Types.OverUnder.Question -> Html Msg
viewQuestion model competition question =
    let
        -- Answer entry comes in the next chunk, for now the answer is only shown.
        answer : Html Msg
        answer =
            case Model.getOverUnderAnswer model competition.id question of
                Nothing ->
                    Html.span
                        [ Attributes.class "over-under-no-answer" ]
                        [ Html.text "Not answered" ]

                Just probability ->
                    Html.span
                        [ Attributes.class "over-under-answer" ]
                        [ percent probability |> Html.text ]

        currentProbability : Html Msg
        currentProbability =
            case question.currentProbability of
                Nothing ->
                    Html.Extra.nothing

                Just probability ->
                    Html.span
                        [ Attributes.class "over-under-current-probability" ]
                        [ percent probability |> Html.text ]

        outcome : Html Msg
        outcome =
            case question.voided of
                True ->
                    Html.span
                        [ Attributes.class "over-under-voided" ]
                        [ Html.text "Voided" ]

                False ->
                    case question.outcome of
                        Nothing ->
                            Html.Extra.nothing

                        Just True ->
                            Html.span
                                [ Attributes.class "over-under-outcome" ]
                                [ Html.text "Yes" ]

                        Just False ->
                            Html.span
                                [ Attributes.class "over-under-outcome" ]
                                [ Html.text "No" ]
    in
    Html.li
        [ Attributes.class "over-under-question" ]
        [ Html.span
            [ Attributes.class "over-under-question-text" ]
            [ Html.text question.text ]
        , answer
        , currentProbability
        , outcome
        ]


viewDescription : Types.OverUnder.Competition -> Html msg
viewDescription competition =
    case competition.description of
        Nothing ->
            Html.Extra.nothing

        Just description ->
            Html.p
                [ Attributes.class "over-under-competition-description" ]
                [ Html.text description ]


viewDeadline : Model key -> Types.OverUnder.Competition -> Html msg
viewDeadline model competition =
    let
        contents : List (Html msg)
        contents =
            case competition.predictionDeadline of
                Nothing ->
                    [ Html.text "No entry deadline has been set." ]

                Just deadline ->
                    case Types.OverUnder.deadlinePassed model.now competition of
                        True ->
                            [ Html.text "Entry closed "
                            , Components.Time.shortFormat model.zone deadline
                            ]

                        False ->
                            [ Html.text "Entry closes "
                            , Components.Time.shortFormat model.zone deadline
                            ]
    in
    Html.p
        [ Attributes.class "over-under-deadline" ]
        contents


viewAnsweredCount : Model key -> Types.OverUnder.Competition -> Html msg
viewAnsweredCount model competition =
    let
        total : Int
        total =
            List.length competition.questions

        contents : List (Html msg)
        contents =
            case Helpers.Http.toMaybe model.userStatus of
                Nothing ->
                    [ [ String.fromInt total, " questions" ]
                        |> String.concat
                        |> Html.text
                    ]

                Just _ ->
                    let
                        answered : Int
                        answered =
                            competition.questions
                                |> List.filterMap (Model.getOverUnderAnswer model competition.id)
                                |> List.length
                    in
                    [ [ String.fromInt answered
                      , " of "
                      , String.fromInt total
                      , " answered"
                      ]
                        |> String.concat
                        |> Html.text
                    ]
    in
    Html.p
        [ Attributes.class "over-under-answered-count" ]
        contents


percent : Int -> String
percent probability =
    String.fromInt probability
        |> (\p -> String.append p "%")
