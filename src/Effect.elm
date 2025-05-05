module Effect exposing
    ( Effect(..)
    , goto
    )

import Route exposing (Route)
import Types.FormulaE
import Types.FormulaOne
import Types.Login


type Effect
    = None
    | Batch (List Effect)
    | PushUrl String
    | LoadUrl String
    | Reload
    | SubmitLogin Types.Login.Form
    | SubmitLogout
    | GetFormulaOneLeaderboard { season : Types.FormulaOne.Season }
    | GetFormulaOneEvents { season : Types.FormulaOne.Season }
    | GetFormulaOneEventSessions { eventId : Types.FormulaOne.EventId }
    | GetFormulaELeaderboard { season : Types.FormulaE.Season }


goto : Route -> Effect
goto route =
    route
        |> Route.unparse
        |> PushUrl
