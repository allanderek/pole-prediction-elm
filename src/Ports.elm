port module Ports exposing
    ( clear_local_storage
    , local_storage_changed
    , native_alert
    , set_local_storage
    )

import Json.Encode


port local_storage_changed : (Json.Encode.Value -> msg) -> Sub msg


port native_alert : String -> Cmd msg


port set_local_storage : { key : String, value : Json.Encode.Value } -> Cmd msg


port clear_local_storage : String -> Cmd msg
