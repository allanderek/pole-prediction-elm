module Types.Profile exposing
    ( Form
    , encodeForm
    , initForm
    )

import Json.Encode as Encode
import Types.User exposing (User)


type alias Form =
    { fullname : String }


initForm : User -> Form
initForm user =
    { fullname = user.fullname }


encodeForm : Form -> Encode.Value
encodeForm form =
    Encode.object
        [ ( "fullname", Encode.string form.fullname ) ]
