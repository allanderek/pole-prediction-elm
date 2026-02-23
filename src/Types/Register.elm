module Types.Register exposing
    ( Form
    , emptyForm
    , encodeForm
    , isValidForm
    )

import Json.Encode as Encode


type alias Form =
    { username : String
    , password : String
    , email : String
    , fullName : String
    }


emptyForm : Form
emptyForm =
    { username = ""
    , password = ""
    , email = ""
    , fullName = ""
    }


isValidForm : Form -> Bool
isValidForm form =
    String.length form.username > 0 && String.length form.password > 0


encodeForm : Form -> Encode.Value
encodeForm form =
    -- Email and fullname are optional; only include them if non-empty.
    Encode.object
        (List.filterMap identity
            [ Just ( "username", Encode.string form.username )
            , Just ( "password", Encode.string form.password )
            , if String.length form.email > 0 then
                Just ( "email", Encode.string form.email )

              else
                Nothing
            , if String.length form.fullName > 0 then
                Just ( "fullname", Encode.string form.fullName )

              else
                Nothing
            ]
        )
