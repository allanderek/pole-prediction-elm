module Model exposing
    ( Model
    , getFormulaOneCurrentSessionPrediction
    , initial
    )

import Dict exposing (Dict)
import Helpers.Http
import Helpers.List
import Maybe.Extra
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
    , formulaOneSessionEntries : Dict Types.FormulaOne.SessionId (List Types.FormulaOne.Entrant)
    , formulaOneSessionPredictionSubmitStatus : Dict Types.FormulaOne.SessionId (Helpers.Http.Status ())
    , formulaOneSessionLeaderboards : Dict Types.FormulaOne.SessionId (Helpers.Http.Status Types.FormulaOne.SessionLeaderboard)
    , formulaOneSeasonLeaderboards : Dict Types.FormulaOne.Season (Helpers.Http.Status Types.FormulaOne.SeasonLeaderboard)
    , formulaOneConstructorStandings : Dict Types.FormulaOne.Season (Helpers.Http.Status Leaderboard)
    , formulaOneDriverStandings : Dict Types.FormulaOne.Season (Helpers.Http.Status Leaderboard)
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
    , formulaOneSessionEntries = Dict.empty
    , formulaOneSessionPredictionSubmitStatus = Dict.empty
    , formulaOneSessionLeaderboards = Dict.empty
    , formulaOneSeasonLeaderboards = Dict.empty
    , formulaOneConstructorStandings = Dict.empty
    , formulaOneDriverStandings = Dict.empty
    , formulaELeaderboards = Dict.empty
    }


getFormulaOneCurrentSessionPrediction : Model key -> Types.FormulaOne.SessionId -> Maybe (List Types.FormulaOne.Entrant)
getFormulaOneCurrentSessionPrediction model sessionId =
    case Helpers.Http.toMaybe model.userStatus of
        Nothing ->
            Nothing

        Just user ->
            let
                storedPrediction : Maybe (List Types.FormulaOne.Entrant)
                storedPrediction =
                    Dict.get sessionId model.formulaOneSessionLeaderboards
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []
                        |> Helpers.List.findWith user.id .userId
                        |> Maybe.map (.rows >> List.map .entrant)
            in
            Dict.get sessionId model.formulaOneSessionEntries
                |> Maybe.Extra.orElse storedPrediction
