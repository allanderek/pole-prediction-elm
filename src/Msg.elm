module Msg exposing
    ( HttpResult
    , Msg(..)
    )

import Browser
import Http
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
    | LoginIdentityInput String
    | LoginPasswordInput String
    | LoginSubmit
    | LoginSubmitResponse (HttpResult User)
    | Logout
    | LogoutResponse (HttpResult ())
    | FormulaOneLeaderboardResponse { season : Types.FormulaOne.Season } (HttpResult Leaderboard)
    | FormulaOneEventsResponse { season : Types.FormulaOne.Season } (HttpResult (List Types.FormulaOne.Event))
    | FormulaOneEventSessionsResponse { eventId : Types.FormulaOne.EventId } (HttpResult (List Types.FormulaOne.Session))
    | FormulaOneEntrantsResponse { sessionId : Types.FormulaOne.SessionId } (HttpResult (List Types.FormulaOne.Entrant))
    | FormulaOneSessionLeaderboardResponse { sessionId : Types.FormulaOne.SessionId } (HttpResult Types.FormulaOne.SessionLeaderboard)
    | FormulaELeaderboardResponse { season : Types.FormulaE.Season } (HttpResult Leaderboard)
