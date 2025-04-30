module Effect exposing
    ( Effect(..)
    , goto
    )

import Route exposing (Route)
import Types.Login


type Effect
    = None
    | PushUrl String
    | LoadUrl String
    | SubmitLogin Types.Login.Form


goto : Route -> Effect
goto route =
    route
        |> Route.unparse
        |> PushUrl
