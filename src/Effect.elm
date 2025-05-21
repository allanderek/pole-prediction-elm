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
    | GetFormulaOneEntrants { sessionId : Types.FormulaOne.SessionId }
    | GetFormulaOneSessionLeaderboard { sessionId : Types.FormulaOne.SessionId }
    | GetFormulaOneSeasonLeaderboard { season : Types.FormulaOne.Season }
    | GetFormulaOneConstructorStandings { season : Types.FormulaOne.Season }
    | GetFormulaOneDriverStandings { season : Types.FormulaOne.Season }
    | GetFormulaELeaderboard { season : Types.FormulaE.Season }
    | GetFormulaEEvents { season : Types.FormulaE.Season }
    | GetFormulaEEventEntrants { eventId : Types.FormulaE.EventId }
    | GetFormulaEEventLeaderboard { eventId : Types.FormulaE.EventId }
    | SubmitFormulaOneSessionPrediction { sessionId : Types.FormulaOne.SessionId } (List Types.FormulaOne.EntrantId)
    | SubmitFormulaOneSessionResult { sessionId : Types.FormulaOne.SessionId } (List Types.FormulaOne.EntrantId)


goto : Route -> Effect
goto route =
    route
        |> Route.unparse
        |> PushUrl
