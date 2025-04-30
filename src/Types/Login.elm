module Types.Login exposing
    ( Form
    , emptyForm
    , encodeForm
    , isValidForm
    )

import Json.Encode as Encode


type alias Form =
    { username : String
    , password : String
    }


emptyForm : Form
emptyForm =
    { username = ""
    , password = ""
    }


isValidForm : Form -> Bool
isValidForm form =
    (String.length form.username > 0)
        && (String.length form.password > 0)


encodeForm : Form -> Encode.Value
encodeForm form =
    Encode.object
        [ ( "username", Encode.string form.username )
        , ( "password", Encode.string form.password )
        ]
