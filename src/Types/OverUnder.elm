module Types.OverUnder exposing
    ( Choice(..)
    , Competition
    , CompetitionId
    , Question
    , QuestionId
    , choiceOfProbability
    , competitionDecoder
    , deadlinePassed
    , encodeAnswers
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
