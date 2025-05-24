module Msg exposing
    ( HttpResult
    , Msg(..)
    , UpdateFormulaEPredictionMsg(..)
    )

import Browser
import Http
import Time
import TimeZone
import Types.FormulaE
import Types.FormulaOne
import Types.Leaderboard exposing (Leaderboard)
import Types.User exposing (User)
import Url


type alias HttpResult a =
    Result Http.Error a


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GetTimeZone (Result TimeZone.Error ( String, Time.Zone ))
    | LegacyGetTimeZone Time.Zone
    | LoginIdentityInput String
    | LoginPasswordInput String
    | LoginSubmit
    | LoginSubmitResponse (HttpResult User)
    | Logout
    | LogoutResponse (HttpResult ())
    | ReorderFormulaOneSessionPredictionEntry Types.FormulaOne.SessionId Int Int
    | ReorderFormulaOneSessionResultEntry Types.FormulaOne.SessionId Int Int
    | SubmitFormulaOneSessionEntry Types.FormulaOne.SessionId (List Types.FormulaOne.EntrantId)
    | SubmitFormulaOneSessionEntryResponse Types.FormulaOne.SessionId (HttpResult ())
    | SubmitFormulaOneSessionResult Types.FormulaOne.SessionId (List Types.FormulaOne.EntrantId)
    | SubmitFormulaOneSessionResultResponse Types.FormulaOne.SessionId (HttpResult Types.FormulaOne.SessionLeaderboard)
    | FormulaOneLeaderboardResponse { season : Types.FormulaOne.Season } (HttpResult Leaderboard)
    | FormulaOneEventsResponse { season : Types.FormulaOne.Season } (HttpResult (List Types.FormulaOne.Event))
    | FormulaOneEventSessionsResponse { eventId : Types.FormulaOne.EventId } (HttpResult (List Types.FormulaOne.Session))
    | FormulaOneEntrantsResponse { sessionId : Types.FormulaOne.SessionId } (HttpResult (List Types.FormulaOne.Entrant))
    | FormulaOneSessionLeaderboardResponse { sessionId : Types.FormulaOne.SessionId } (HttpResult Types.FormulaOne.SessionLeaderboard)
    | FormulaOneSeasonLeaderboardResponse { season : Types.FormulaOne.Season } (HttpResult Types.FormulaOne.SeasonLeaderboard)
    | FormulaOneConstructorStandingsResponse { season : Types.FormulaOne.Season } (HttpResult Leaderboard)
    | FormulaOneDriverStandingsResponse { season : Types.FormulaOne.Season } (HttpResult Leaderboard)
    | FormulaELeaderboardResponse { season : Types.FormulaE.Season } (HttpResult Leaderboard)
    | FormulaEEventsResponse { season : Types.FormulaE.Season } (HttpResult (List Types.FormulaE.Event))
    | FormulaEEventEntrantsResponse { eventId : Types.FormulaE.EventId } (HttpResult (List Types.FormulaE.Entrant))
    | FormulaEEventLeaderboardResponse { eventId : Types.FormulaE.EventId } (HttpResult Types.FormulaE.EventLeaderboard)
    | UpdateFormulaEPrediction { eventId : Types.FormulaE.EventId } UpdateFormulaEPredictionMsg
    | UpdateFormulaEResult { eventId : Types.FormulaE.EventId } UpdateFormulaEPredictionMsg
    | SubmitFormulaEPrediction { eventId : Types.FormulaE.EventId } Types.FormulaE.Prediction
    | SubmitFormulaEResult { eventId : Types.FormulaE.EventId } Types.FormulaE.Result
    | SubmitFormulaEPredictionResponse { eventId : Types.FormulaE.EventId } (HttpResult Types.FormulaE.EventLeaderboard)
    | SubmitFormulaEResultResponse { eventId : Types.FormulaE.EventId } (HttpResult Types.FormulaE.EventLeaderboard)



-- | SubmitFormulaEPrediction { eventId : Types.FormulaE.EventId } Types.FormulaE.Prediction
-- | SubmitFormulaEResult { eventId : Types.FormulaE.EventId } Types.FormulaE.Prediction


type UpdateFormulaEPredictionMsg
    = SetPole Types.FormulaE.EntrantId
    | SetFam Types.FormulaE.EntrantId
    | SetFastestLap Types.FormulaE.EntrantId
    | SetHgc Types.FormulaE.EntrantId
    | SetFirst Types.FormulaE.EntrantId
    | SetSecond Types.FormulaE.EntrantId
    | SetThird Types.FormulaE.EntrantId
    | SetFdnf Types.FormulaE.EntrantId
    | SetSafetyCar Bool
