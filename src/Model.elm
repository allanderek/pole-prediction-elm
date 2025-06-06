module Model exposing
    ( Model
    , getFormulaEEventPrediction
    , getFormulaEEventResult
    , getFormulaOneCurrentSessionPrediction
    , getFormulaOneCurrentSessionResults
    , getFromStatusDict
    , initial
    )

import Dict exposing (Dict)
import Helpers.Http
import Helpers.List
import Maybe.Extra
import Route exposing (Route)
import Time
import Types.FormulaE
import Types.FormulaOne
import Types.Leaderboard exposing (Leaderboard)
import Types.Login
import Types.Profile
import Types.User exposing (User)
import Url exposing (Url)


type alias Model key =
    { navigationKey : key
    , route : Route
    , now : Time.Posix
    , zone : Time.Zone
    , userStatus : Helpers.Http.Status User
    , loginForm : Types.Login.Form
    , editingProfile : Bool
    , profileForm : Maybe Types.Profile.Form
    , profileStatus : Helpers.Http.Status User
    , formulaOneLeaderboards : Dict Types.FormulaOne.Season (Helpers.Http.Status Leaderboard)
    , formulaOneEvents : Dict Types.FormulaOne.Season (Helpers.Http.Status (List Types.FormulaOne.Event))
    , formulaOneSessions : Dict Types.FormulaOne.EventId (Helpers.Http.Status (List Types.FormulaOne.Session))
    , formulaOneEntrants : Dict Types.FormulaOne.SessionId (Helpers.Http.Status (List Types.FormulaOne.Entrant))
    , formulaOneSessionPredictionEntries : Dict Types.FormulaOne.SessionId (List Types.FormulaOne.Entrant)
    , formulaOneSessionResultEntries : Dict Types.FormulaOne.SessionId (List Types.FormulaOne.Entrant)
    , formulaOneSessionPredictionSubmitStatus : Dict Types.FormulaOne.SessionId (Helpers.Http.Status ())
    , formulaOneSessionResultSubmitStatus : Dict Types.FormulaOne.SessionId (Helpers.Http.Status ())
    , formulaOneSessionLeaderboards : Dict Types.FormulaOne.SessionId (Helpers.Http.Status Types.FormulaOne.SessionLeaderboard)
    , formulaOneSeasonLeaderboards : Dict Types.FormulaOne.Season (Helpers.Http.Status Types.FormulaOne.SeasonLeaderboard)
    , formulaOneConstructorStandings : Dict Types.FormulaOne.Season (Helpers.Http.Status Leaderboard)
    , formulaOneDriverStandings : Dict Types.FormulaOne.Season (Helpers.Http.Status Leaderboard)
    , formulaELeaderboards : Dict Types.FormulaE.Season (Helpers.Http.Status Leaderboard)
    , formulaEEvents : Dict Types.FormulaE.Season (Helpers.Http.Status (List Types.FormulaE.Event))
    , formulaEEventEntrants : Dict Types.FormulaE.EventId (Helpers.Http.Status (List Types.FormulaE.Entrant))
    , formulaEPredictionInputs : Dict Types.FormulaE.EventId Types.FormulaE.Prediction
    , formulaEResultInputs : Dict Types.FormulaE.EventId Types.FormulaE.Result
    , formulaEEventLeaderboards : Dict Types.FormulaE.EventId (Helpers.Http.Status Types.FormulaE.EventLeaderboard)
    }


initial : key -> Url -> Time.Posix -> Helpers.Http.Status User -> Model key
initial key url now userStatus =
    { navigationKey = key
    , route = Route.parse url
    , now = now
    , zone = Time.utc
    , userStatus = userStatus
    , loginForm = Types.Login.emptyForm
    , editingProfile = False
    , profileForm = Nothing
    , profileStatus = Helpers.Http.Ready
    , formulaOneLeaderboards = Dict.empty
    , formulaOneEvents = Dict.empty
    , formulaOneSessions = Dict.empty
    , formulaOneEntrants = Dict.empty
    , formulaOneSessionPredictionEntries = Dict.empty
    , formulaOneSessionResultEntries = Dict.empty
    , formulaOneSessionPredictionSubmitStatus = Dict.empty
    , formulaOneSessionResultSubmitStatus = Dict.empty
    , formulaOneSessionLeaderboards = Dict.empty
    , formulaOneSeasonLeaderboards = Dict.empty
    , formulaOneConstructorStandings = Dict.empty
    , formulaOneDriverStandings = Dict.empty
    , formulaELeaderboards = Dict.empty
    , formulaEEvents = Dict.empty
    , formulaEEventEntrants = Dict.empty
    , formulaEPredictionInputs = Dict.empty
    , formulaEResultInputs = Dict.empty
    , formulaEEventLeaderboards = Dict.empty
    }


getFromStatusDict : comparable -> Dict comparable (Helpers.Http.Status a) -> Maybe a
getFromStatusDict key dict =
    Dict.get key dict
        |> Maybe.withDefault Helpers.Http.Ready
        |> Helpers.Http.toMaybe


andThenWithUser : (User -> Maybe a) -> Model key -> Maybe a
andThenWithUser f model =
    Helpers.Http.toMaybe model.userStatus
        |> Maybe.andThen f


getFormulaOneCurrentSessionPrediction : Model key -> Types.FormulaOne.SessionId -> Maybe (List Types.FormulaOne.Entrant)
getFormulaOneCurrentSessionPrediction model sessionId =
    let
        calculateWithUser : User -> Maybe (List Types.FormulaOne.Entrant)
        calculateWithUser user =
            let
                storedPrediction : Maybe (List Types.FormulaOne.Entrant)
                storedPrediction =
                    getFromStatusDict sessionId model.formulaOneSessionLeaderboards
                        |> Maybe.map .predictions
                        |> Maybe.withDefault []
                        |> Helpers.List.findWith user.id .userId
                        |> Maybe.map (.rows >> List.map .entrant)
            in
            Dict.get sessionId model.formulaOneSessionPredictionEntries
                |> Maybe.Extra.orElse storedPrediction
    in
    andThenWithUser calculateWithUser model


getFormulaOneCurrentSessionResults : Model key -> Types.FormulaOne.SessionId -> Maybe (List Types.FormulaOne.Entrant)
getFormulaOneCurrentSessionResults model sessionId =
    let
        storedResult : Maybe (List Types.FormulaOne.Entrant)
        storedResult =
            getFromStatusDict sessionId model.formulaOneSessionLeaderboards
                |> Maybe.map .results
                |> Maybe.andThen Helpers.List.emptyAsNothing
    in
    Dict.get sessionId model.formulaOneSessionResultEntries
        |> Maybe.Extra.orElse storedResult


getFormulaEEventPrediction : Model key -> User -> Types.FormulaE.EventId -> Types.FormulaE.Prediction
getFormulaEEventPrediction model user eventId =
    case Dict.get eventId model.formulaEPredictionInputs of
        Just prediction ->
            prediction

        Nothing ->
            getFromStatusDict eventId model.formulaEEventLeaderboards
                |> Maybe.map .predictions
                |> Maybe.withDefault []
                |> Helpers.List.findWith user.id .userId
                |> Maybe.map .prediction
                |> Maybe.withDefault Types.FormulaE.emptyPrediction


getFormulaEEventResult : Model key -> Types.FormulaE.EventId -> Types.FormulaE.Result
getFormulaEEventResult model eventId =
    case Dict.get eventId model.formulaEResultInputs of
        Just result ->
            result

        Nothing ->
            getFromStatusDict eventId model.formulaEEventLeaderboards
                |> Maybe.andThen .result
                |> Maybe.withDefault Types.FormulaE.emptyPrediction
