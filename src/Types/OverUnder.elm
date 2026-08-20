module Types.OverUnder exposing
    ( Competition
    , CompetitionId
    , Question
    , QuestionId
    , competitionDecoder
    , deadlinePassed
    )

import Helpers.Decode
import Helpers.Rfc3339
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
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
