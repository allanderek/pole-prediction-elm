module Effect exposing
    ( Effect(..)
    , goto
    )

import Json.Encode
import Route exposing (Route)
import Types.Data exposing (Data)
import Types.FormulaE
import Types.FormulaOne
import Types.Login
import Types.Profile


type Effect
    = None
    | Batch (List Effect)
    | PushUrl String
    | LoadUrl String
    | Reload
    | SetLocalStorage String Json.Encode.Value
    | ClearLocalStorage String
    | NativeAlert String
    | GetTimeZone
    | LegacyGetTimeZone
    | SubmitLogin Types.Login.Form
    | SubmitLogout
    | SubmitProfile Types.Profile.Form
    | GetData Data
    | SubmitFormulaEPrediction { eventId : Types.FormulaE.EventId } Types.FormulaE.Prediction
    | SubmitFormulaEResult { eventId : Types.FormulaE.EventId } Types.FormulaE.Result
    | SubmitFormulaOneSessionPrediction { sessionId : Types.FormulaOne.SessionId } (List Types.FormulaOne.EntrantId)
    | SubmitFormulaOneSessionResult { sessionId : Types.FormulaOne.SessionId } (List Types.FormulaOne.EntrantId)


goto : Route -> Effect
goto route =
    route
        |> Route.unparse
        |> PushUrl
