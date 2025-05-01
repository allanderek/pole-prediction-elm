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
    | Reload
    | SubmitLogin Types.Login.Form
    | SubmitLogout


goto : Route -> Effect
goto route =
    route
        |> Route.unparse
        |> PushUrl
