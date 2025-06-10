module Types.LocalStorageNotification exposing
    ( LocalStorageNotification(..)
    , decoder
    )

import Json.Decode exposing (Decoder)
import Types.User exposing (User)


type LocalStorageNotification
    = UserUpdated (Maybe User)


decoder : Decoder LocalStorageNotification
decoder =
    let
        interpretKey : String -> Decoder LocalStorageNotification
        interpretKey key =
            case key of
                "user" ->
                    -- We use nullable here, the 'newValue' field will always be there because we explicitly set it
                    -- during handler for local storage events (see services/frontpage/index-admin.go search for
                    -- local_storage_changed). It can be null, which means the user has logged out. Note though that
                    -- if the user is *there* and doesn't decode, then the decoder will fail, and we will ignore it
                    -- as though it was a local storage event that we do nto care about.
                    Json.Decode.field "newValue" (Json.Decode.nullable Types.User.decoder)
                        |> Json.Decode.map UserUpdated

                _ ->
                    String.append "Unwatched local storage key: " key
                        |> Json.Decode.fail
    in
    Json.Decode.field "key" Json.Decode.string
        |> Json.Decode.andThen interpretKey
