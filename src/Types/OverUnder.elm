module Types.OverUnder exposing
    ( Choice(..)
    , Competition
    , CompetitionId
    , Leaderboard
    , LeaderboardCell
    , LeaderboardRow
    , Question
    , QuestionId
    , answerLabel
    , choiceOfProbability
    , competitionDecoder
    , currentProbabilityLabel
    , deadlinePassed
    , encodeAnswers
    , leaderboardDecoder
    , outcomeLabel
    , numberQuestions
    , overProbability
    , underProbability
    )

import Helpers.Decode
import Helpers.Rfc3339
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode
import Time


type alias CompetitionId =
    Int


type alias QuestionId =
    Int


type alias Competition =
    { id : CompetitionId
    , name : String
    , description : Maybe String
    , predictionDeadline : Maybe Time.Posix
    , questions : List Question
    }


{-| A question is a binary event, 'over/under' is just the phrasing, and any numeric
line lives in the text. Both the user's `answer` and our own `currentProbability` are
the probability, from 0 to 100, that the outcome is True.

The server only sends `currentProbability` once the deadline has passed, so that it
does not give the answers away while the questions can still be answered.

-}
type alias Question =
    { id : QuestionId
    , text : String
    , currentProbability : Maybe Int
    , outcome : Maybe Bool
    , resolvedAt : Maybe Time.Posix
    , voided : Bool
    , answer : Maybe Int
    }


competitionDecoder : Decoder Competition
competitionDecoder =
    Decode.succeed Competition
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "description" (Decode.nullable Decode.string)
        |> Pipeline.required "prediction_deadline" (Decode.nullable Helpers.Rfc3339.decoder)
        |> Pipeline.required "questions" (Decode.list questionDecoder)


questionDecoder : Decoder Question
questionDecoder =
    Decode.succeed Question
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "text" Decode.string
        |> Pipeline.required "current_probability" (Decode.nullable Decode.int)
        |> Pipeline.required "outcome" (Decode.nullable Helpers.Decode.intAsBool)
        |> Pipeline.required "resolved_at" (Decode.nullable Helpers.Rfc3339.decoder)
        |> Pipeline.required "voided" Decode.bool
        |> Pipeline.required "answer" (Decode.nullable Decode.int)


{-| Worked out on the client from `model.now`, rather than taken from the server's own
`deadline_passed`, so that the page changes over by itself when the deadline passes.
A competition with no deadline is never closed, which matches the submit endpoint.
-}
deadlinePassed : Time.Posix -> Competition -> Bool
deadlinePassed now competition =
    case competition.predictionDeadline of
        Nothing ->
            False

        Just deadline ->
            Time.posixToMillis deadline <= Time.posixToMillis now


{-| For this first competition we ask only for over or under, with no confidence, so
that answering is as light as possible. Those are stored as the two extremes of the
probability the database and the endpoint already accept, which leaves the way open to
ask for a confidence later without changing anything underneath.
-}
type Choice
    = Over
    | Under


overProbability : Int
overProbability =
    100


underProbability : Int
underProbability =
    0


{-| A stored probability that is neither extreme is not something this UI can produce,
so it is reported as `Nothing` rather than being rounded to the nearer button.
-}
choiceOfProbability : Int -> Maybe Choice
choiceOfProbability probability =
    case probability == overProbability of
        True ->
            Just Over

        False ->
            case probability == underProbability of
                True ->
                    Just Under

                False ->
                    Nothing


{-| This does not use Types.Leaderboard, whose cells are a bare score. A score on its own
does not say what the player actually answered, and where a question has no recorded view
the target defaults to 50, so both answers score exactly 50 and the score cannot say
anything at all. Each cell therefore carries the answer as well.

`serverDeadlinePassed` is what the *server* believed when it built this, which is not
always what our own clock says. The page uses our clock to decide what to draw, and this
to decide whether the answers it is holding are the real, post-deadline ones.

-}
type alias Leaderboard =
    { serverDeadlinePassed : Bool
    , columns : List String
    , rows : List LeaderboardRow
    }


type alias LeaderboardRow =
    { id : Int
    , name : String
    , cells : List LeaderboardCell
    , total : Int
    }


type alias LeaderboardCell =
    { probability : Maybe Int
    , score : Int
    }


leaderboardDecoder : Decoder Leaderboard
leaderboardDecoder =
    let
        cellDecoder : Decoder LeaderboardCell
        cellDecoder =
            Decode.succeed LeaderboardCell
                |> Pipeline.required "probability" (Decode.nullable Decode.int)
                |> Pipeline.required "score" Decode.int

        rowDecoder : Decoder LeaderboardRow
        rowDecoder =
            Decode.succeed LeaderboardRow
                |> Pipeline.required "id" Decode.int
                |> Pipeline.required "name" Decode.string
                |> Pipeline.required "cells" (Decode.list cellDecoder)
                |> Pipeline.required "total" Decode.int
    in
    Decode.succeed Leaderboard
        |> Pipeline.required "deadline_passed" Decode.bool
        |> Pipeline.required "columns" (Decode.list Decode.string)
        |> Pipeline.required "rows" (Decode.list rowDecoder)


{-| How an answer is written, wherever it is shown. Kept here rather than in the pages so
that the question list and the leaderboard can never disagree about what a stored
probability means.
-}
answerLabel : Int -> String
answerLabel probability =
    case choiceOfProbability probability of
        Just Over ->
            "Over"

        Just Under ->
            "Under"

        Nothing ->
            String.fromInt probability
                |> (\p -> String.append p "%")


{-| How a question turned out. This is a fact about the question, not about anybody's
answer, so it is stated the same way whoever is looking and whether or not they answered.
Defined in terms of answerLabel so the two vocabularies cannot drift apart.
-}
outcomeLabel : Bool -> String
outcomeLabel outcome =
    case outcome of
        True ->
            answerLabel overProbability

        False ->
            answerLabel underProbability


{-| Our current view of an unresolved question. The stored number is the probability of
the *over* case, so showing it bare would leave the reader guessing which way it points.
-}
currentProbabilityLabel : Int -> String
currentProbabilityLabel probability =
    String.concat
        [ answerLabel overProbability
        , " "
        , String.fromInt probability
        , "%"
        ]


{-| Numbers the questions to match the leaderboard's Q1..Qn columns. Voided questions
are left out of the scoring and so out of the columns, and therefore must not consume a
number here either, or the labels would not line up with the table.
-}
numberQuestions : List Question -> List ( Maybe Int, Question )
numberQuestions questions =
    let
        step : Question -> ( Int, List ( Maybe Int, Question ) ) -> ( Int, List ( Maybe Int, Question ) )
        step question ( next, sofar ) =
            case question.voided of
                True ->
                    ( next, ( Nothing, question ) :: sofar )

                False ->
                    ( next + 1, ( Just next, question ) :: sofar )
    in
    List.foldl step ( 1, [] ) questions
        |> Tuple.second
        |> List.reverse


encodeAnswers : List ( QuestionId, Int ) -> Json.Encode.Value
encodeAnswers answers =
    let
        encodeAnswer : ( QuestionId, Int ) -> Json.Encode.Value
        encodeAnswer ( questionId, probability ) =
            Json.Encode.object
                [ ( "question", Json.Encode.int questionId )
                , ( "probability", Json.Encode.int probability )
                ]
    in
    Json.Encode.object
        [ ( "answers", Json.Encode.list encodeAnswer answers ) ]
