module Types.Leaderboard exposing
    ( Leaderboard
    , LeaderboardRow
    , decoder
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline


type alias Leaderboard =
    { columns : List String
    , rows : List LeaderboardRow
    }


type alias LeaderboardRow =
    { userId : Int
    , userName : String
    , scores : List Int
    }


decoder : Decoder Leaderboard
decoder =
    let
        rowDecoder : Decoder LeaderboardRow
        rowDecoder =
            Decode.succeed LeaderboardRow
                |> Pipeline.required "userId" Decode.int
                |> Pipeline.required "userName" Decode.string
                |> Pipeline.required "scores" (Decode.list Decode.int)
    in
    Decode.succeed Leaderboard
        |> Pipeline.required "columns" (Decode.list Decode.string)
        |> Pipeline.required "rows" (Decode.list rowDecoder)
