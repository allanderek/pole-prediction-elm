module Model exposing
    ( Model
    , initial
    )

import Route exposing (Route)
import Types.Login
import Types.User exposing (User)
import Url exposing (Url)


type alias Model key =
    { navigationKey : key
    , route : Route
    , mUser : Maybe User
    , loginForm : Types.Login.Form
    }


initial : key -> Url -> Model key
initial key url =
    { navigationKey = key
    , route = Route.parse url
    , mUser = Nothing
    , loginForm = Types.Login.emptyForm
    }
