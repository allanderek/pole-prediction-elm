module Msg exposing (Msg(..))

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
    | FormulaELeaderboardResponse { season : Types.FormulaE.Season } (HttpResult Leaderboard)
