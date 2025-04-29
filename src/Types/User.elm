module Types.User exposing
    ( User
    , decoder
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline


type alias User =
    { username : String
    , fullname : String
    , isAdmin : Bool
    }


decoder : Decoder User
decoder =
    Decode.succeed User
        |> Pipeline.required "username" Decode.string
        |> Pipeline.required "fullname" Decode.string
        |> Pipeline.required "admin" Decode.bool
