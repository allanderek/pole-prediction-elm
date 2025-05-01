module Msg exposing (Msg(..))

import Browser
import Http
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
