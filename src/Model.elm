module Model exposing
    ( Model
    , initial
    )

import Route exposing (Route)
import Url exposing (Url)


type alias Model key =
    { navigationKey : key
    , route : Route
    }


initial : key -> Url -> Model key
initial key url =
    { navigationKey = key
    , route = Route.parse url
    }
