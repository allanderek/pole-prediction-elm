module Update exposing
    ( initRoute
    , update
    )

import Browser
import Dict
import Effect exposing (Effect)
import Helpers.Http
import Model exposing (Model)
import Msg exposing (Msg)
import Return
import Route
import Types.FormulaE
import Types.FormulaOne
import Types.Login
import Url


initRoute : Model key -> ( Model key, Effect )
initRoute model =
    case model.route of
        Route.Home ->
            Return.noEffect model

        Route.Login ->
            Return.noEffect model

        Route.FormulaOne ->
            ( { model
                | formulaOneLeaderboards =
                    Dict.insert Types.FormulaOne.currentSeason Helpers.Http.Inflight model.formulaOneLeaderboards
              }
            , Effect.GetFormulaOneLeaderboard { season = Types.FormulaOne.currentSeason }
            )

        Route.FormulaE ->
            ( { model
                | formulaELeaderboards =
                    Dict.insert Types.FormulaE.currentSeason Helpers.Http.Inflight model.formulaELeaderboards
              }
            , Effect.GetFormulaELeaderboard { season = Types.FormulaE.currentSeason }
            )

        Route.Profile ->
            Return.noEffect model

        Route.NotFound ->
            Return.noEffect model


update : Msg -> Model key -> ( Model key, Effect )
update msg model =
    case msg of
        Msg.LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Effect.PushUrl (Url.toString url)
                    )

                Browser.External href ->
                    ( model
                    , Effect.LoadUrl href
                    )

        Msg.UrlChanged url ->
            initRoute
                { model | route = Route.parse url }

        Msg.LoginIdentityInput input ->
            let
                form : Types.Login.Form
                form =
                    model.loginForm
            in
            Return.noEffect
                { model | loginForm = { form | username = input } }

        Msg.LoginPasswordInput input ->
            let
                form : Types.Login.Form
                form =
                    model.loginForm
            in
            Return.noEffect
                { model | loginForm = { form | password = input } }

        Msg.LoginSubmit ->
            case Types.Login.isValidForm model.loginForm of
                False ->
                    Return.noEffect model

                True ->
                    ( { model | userStatus = Helpers.Http.Inflight }
                    , Effect.SubmitLogin model.loginForm
                    )

        Msg.LoginSubmitResponse result ->
            ( { model | userStatus = Helpers.Http.fromResult result }
            , case result of
                Err _ ->
                    Effect.None

                Ok _ ->
                    Effect.goto Route.Home
            )

        Msg.Logout ->
            ( model, Effect.SubmitLogout )

        Msg.LogoutResponse _ ->
            -- It doesn't really matter what the result is, since even with success
            -- we're just going to reload the current page, so any updates we do here would
            -- be lost anyway. If this fails, then we could set the user status to the failure,
            -- but then that would look like you were logged-out when maybe actually you weren't.
            -- So we just ignore the result and reload the page.
            ( model, Effect.Reload )

        Msg.FormulaOneLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneLeaderboards =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneLeaderboards
                }

        Msg.FormulaELeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaELeaderboards =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaELeaderboards
                }
