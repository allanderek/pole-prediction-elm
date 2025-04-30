module Model exposing
    ( Model
    , initial
    )

import Helpers.Http
import Route exposing (Route)
import Types.Login
import Types.User exposing (User)
import Url exposing (Url)


type alias Model key =
    { navigationKey : key
    , route : Route
    , userStatus : Helpers.Http.Status User
    , loginForm : Types.Login.Form
    }


initial : key -> Url -> Model key
initial key url =
    { navigationKey = key
    , route = Route.parse url
    , userStatus = Helpers.Http.Ready
    , loginForm = Types.Login.emptyForm
    }
