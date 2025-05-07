module Model exposing
    ( Model
    , initial
    )

import Dict exposing (Dict)
import Helpers.Http
import Route exposing (Route)
import Types.FormulaE
import Types.FormulaOne
import Types.Leaderboard exposing (Leaderboard)
import Types.Login
import Types.User exposing (User)
import Url exposing (Url)


type alias Model key =
    { navigationKey : key
    , route : Route
    , userStatus : Helpers.Http.Status User
    , loginForm : Types.Login.Form
    , formulaOneLeaderboards : Dict Types.FormulaOne.Season (Helpers.Http.Status Leaderboard)
    , formulaOneEvents : Dict Types.FormulaOne.Season (Helpers.Http.Status (List Types.FormulaOne.Event))
    , formulaOneSessions : Dict Types.FormulaOne.EventId (Helpers.Http.Status (List Types.FormulaOne.Session))
    , formulaOneEntrants : Dict Types.FormulaOne.SessionId (Helpers.Http.Status (List Types.FormulaOne.Entrant))
    , formulaOneSessionLeaderboards : Dict Types.FormulaOne.SessionId (Helpers.Http.Status Types.FormulaOne.SessionLeaderboard)
    , formulaELeaderboards : Dict Types.FormulaE.Season (Helpers.Http.Status Leaderboard)
    }


initial : key -> Url -> Helpers.Http.Status User -> Model key
initial key url userStatus =
    { navigationKey = key
    , route = Route.parse url
    , userStatus = userStatus
    , loginForm = Types.Login.emptyForm
    , formulaOneLeaderboards = Dict.empty
    , formulaOneEvents = Dict.empty
    , formulaOneSessions = Dict.empty
    , formulaOneEntrants = Dict.empty
    , formulaOneSessionLeaderboards = Dict.empty
    , formulaELeaderboards = Dict.empty
    }
