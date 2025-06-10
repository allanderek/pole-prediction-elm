module Types.User exposing
    ( Id
    , User
    , decoder
    , encode
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode


type alias Id =
    Int


type alias User =
    { id : Id
    , username : String
    , fullname : String
    , isAdmin : Bool
    }


decoder : Decoder User
decoder =
    Decode.succeed User
        |> Pipeline.required "id" Decode.int
        |> Pipeline.required "username" Decode.string
        |> Pipeline.required "fullname" Decode.string
        |> Pipeline.required "admin" Decode.bool


encode : User -> Encode.Value
encode user =
    Encode.object
        [ ( "id", Encode.int user.id )
        , ( "username", Encode.string user.username )
        , ( "fullname", Encode.string user.fullname )
        , ( "admin", Encode.bool user.isAdmin )
        ]
