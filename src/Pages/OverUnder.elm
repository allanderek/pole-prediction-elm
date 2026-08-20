module Pages.OverUnder exposing
    ( viewCompetition
    , viewCompetitionList
    )

import Components.HttpStatus
import Components.OverUnderLeaderboard
import Components.Section
import Components.Time
import Dict
import Helpers.Classes
import Helpers.Events
import Helpers.Http
import Helpers.List
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
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
        open : Bool
        open =
            Types.OverUnder.deadlinePassed model.now competition
                |> not

        questionsSection : Html Msg
        questionsSection =
            case open of
                True ->
                    Components.Section.view
                        { title = "Questions"
                        , class = "over-under-questions"
                        }
                        (viewQuestionList model competition open
                            :: viewEntryControls model competition
                        )

                False ->
                    Components.Section.view
                        { title = "Results"
                        , class = "over-under-results"
                        }
                        [ viewQuestionList model competition open
                        , viewLeaderboard model competition
                        ]
    in
    [ Html.h1
        []
        [ Html.text competition.name ]
    , viewDescription competition
    , viewDeadline model competition
    , questionsSection
    ]


viewLeaderboard : Model key -> Types.OverUnder.Competition -> Html Msg
viewLeaderboard model competition =
    let
        status : Helpers.Http.Status Types.OverUnder.Leaderboard
        status =
            Dict.get competition.id model.overUnderLeaderboards
                |> Maybe.withDefault Helpers.Http.Ready

        viewFn : Types.OverUnder.Leaderboard -> Html Msg
        viewFn leaderboard =
            case leaderboard.serverDeadlinePassed of
                False ->
                    -- Our clock says entry has closed but the server's does not yet, so
                    -- it has quite rightly not given us anyone's answers. We ask again
                    -- on each tick until it agrees.
                    Html.p
                        [ Attributes.class "over-under-awaiting-close" ]
                        [ Html.text "Entry has just closed, collecting everyone's answers..." ]

                True ->
                    Components.OverUnderLeaderboard.view leaderboard
    in
    Components.HttpStatus.view
        { viewFn = viewFn
        , failedMessage = "Error obtaining the leaderboard"
        }
        status


{-| Below the questions: either a prompt to log in, or the submit button. Answering is
explicit rather than saving on each click, so that you can change your mind freely
before committing.
-}
viewEntryControls : Model key -> Types.OverUnder.Competition -> List (Html Msg)
viewEntryControls model competition =
    case Helpers.Http.toMaybe model.userStatus of
        Nothing ->
            [ Html.p
                [ Attributes.class "over-under-login-prompt" ]
                [ Html.text "You need to "
                , Html.a
                    [ Route.href Route.Login ]
                    [ Html.text "log in" ]
                , Html.text " to answer these questions."
                ]
            ]

        Just _ ->
            let
                answers : List ( Types.OverUnder.QuestionId, Int )
                answers =
                    currentAnswers model competition

                inflight : Bool
                inflight =
                    Dict.get competition.id model.overUnderAnswerSubmitStatus
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.isInflight

                disabled : Bool
                disabled =
                    inflight || List.isEmpty answers
            in
            [ Html.button
                [ Attributes.class "over-under-submit"
                , Msg.SubmitOverUnderAnswers competition.id answers
                    |> Helpers.Events.onClickOrDisabled disabled
                ]
                [ Html.text "Submit answers" ]
            ]


{-| Every answer we hold for the competition, not only the ones just clicked. The
endpoint upserts, so sending them all is idempotent and a half finished competition
submits perfectly well.
-}
currentAnswers : Model key -> Types.OverUnder.Competition -> List ( Types.OverUnder.QuestionId, Int )
currentAnswers model competition =
    let
        answerOf : Types.OverUnder.Question -> Maybe ( Types.OverUnder.QuestionId, Int )
        answerOf question =
            Model.getOverUnderAnswer model competition.id question
                |> Maybe.map (Tuple.pair question.id)
    in
    List.filterMap answerOf competition.questions


viewQuestionList : Model key -> Types.OverUnder.Competition -> Bool -> Html Msg
viewQuestionList model competition open =
    case competition.questions of
        [] ->
            Html.text "This competition has no questions yet."

        _ ->
            Html.ul
                [ Attributes.class "over-under-question-list" ]
                (Types.OverUnder.numberQuestions competition.questions
                    |> List.map (viewQuestion model competition open)
                )


viewQuestion : Model key -> Types.OverUnder.Competition -> Bool -> ( Maybe Int, Types.OverUnder.Question ) -> Html Msg
viewQuestion model competition open ( mNumber, question ) =
    let
        -- The label ties the question to its column in the leaderboard table.
        label : Html Msg
        label =
            case mNumber of
                Nothing ->
                    Html.Extra.nothing

                Just number ->
                    Html.span
                        [ Attributes.class "over-under-question-number" ]
                        [ String.fromInt number
                            |> String.append "Q"
                            |> Html.text
                        ]

        mAnswer : Maybe Int
        mAnswer =
            Model.getOverUnderAnswer model competition.id question

        loggedIn : Bool
        loggedIn =
            Helpers.Http.toMaybe model.userStatus /= Nothing

        answer : Html Msg
        answer =
            case open && loggedIn of
                True ->
                    viewChoiceButtons competition question mAnswer

                False ->
                    viewAnswerReadOnly mAnswer

        currentProbability : Html Msg
        currentProbability =
            case question.currentProbability of
                Nothing ->
                    Html.Extra.nothing

                Just probability ->
                    Html.span
                        [ Attributes.class "over-under-current-probability" ]
                        [ Types.OverUnder.currentProbabilityLabel probability |> Html.text ]

        -- How the question turned out, which has nothing to do with who is looking or
        -- whether they answered, so it reads the same way for everyone.
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

                        Just resolved ->
                            Html.span
                                [ Attributes.class "over-under-outcome"
                                , Types.OverUnder.outcomeClass resolved |> Attributes.class
                                ]
                                [ Types.OverUnder.outcomeLabel resolved |> Html.text ]
    in
    Html.li
        [ Attributes.class "over-under-question" ]
        [ label
        , Html.span
            [ Attributes.class "over-under-question-text" ]
            [ Html.text question.text ]
        , answer
        , currentProbability
        , outcome
        ]


{-| Two buttons, over and under, with no confidence asked for. They submit the two
extremes of the probability that the endpoint stores, so asking for a confidence later
is a change to this view rather than to anything underneath it.
-}
viewChoiceButtons : Types.OverUnder.Competition -> Types.OverUnder.Question -> Maybe Int -> Html Msg
viewChoiceButtons competition question mAnswer =
    let
        mChoice : Maybe Types.OverUnder.Choice
        mChoice =
            Maybe.andThen Types.OverUnder.choiceOfProbability mAnswer

        viewButton : Types.OverUnder.Choice -> String -> Int -> Html Msg
        viewButton choice label probability =
            Html.button
                [ Attributes.class "over-under-choice"
                , Helpers.Classes.active (mChoice == Just choice)
                , Msg.SetOverUnderAnswer competition.id question.id probability
                    |> Events.onClick
                ]
                [ Html.text label ]

        -- A stored probability that is neither extreme cannot come from these buttons,
        -- so rather than light up the nearer one we show the number alongside them.
        unexpectedProbability : Html Msg
        unexpectedProbability =
            case ( mAnswer, mChoice ) of
                ( Just probability, Nothing ) ->
                    Html.span
                        [ Attributes.class "over-under-answer" ]
                        [ percent probability |> Html.text ]

                _ ->
                    Html.Extra.nothing
    in
    Html.span
        [ Attributes.class "over-under-choices" ]
        [ viewButton Types.OverUnder.Under "Under" Types.OverUnder.underProbability
        , viewButton Types.OverUnder.Over "Over" Types.OverUnder.overProbability
        , unexpectedProbability
        ]


viewAnswerReadOnly : Maybe Int -> Html Msg
viewAnswerReadOnly mAnswer =
    case mAnswer of
        Nothing ->
            Html.span
                [ Attributes.class "over-under-no-answer" ]
                [ Html.text "Not answered" ]

        Just probability ->
            Html.span
                [ Attributes.class "over-under-answer"
                , Types.OverUnder.answerClass probability |> Attributes.class
                ]
                [ Types.OverUnder.answerLabel probability |> Html.text ]


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
