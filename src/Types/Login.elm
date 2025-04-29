module Types.Login exposing
    ( Form
    , emptyForm
    , encodeForm
    )

import Json.Encode as Encode


type alias Form =
    { identity : String
    , password : String
    }


emptyForm : Form
emptyForm =
    { identity = ""
    , password = ""
    }


encodeForm : Form -> Encode.Value
encodeForm form =
    Encode.object
        [ ( "identity", Encode.string form.identity )
        , ( "password", Encode.string form.password )
        ]
