module Update exposing
    ( initRoute
    , update
    )

import Browser
import Dict
import Effect exposing (Effect)
import Helpers.Http
import Helpers.List
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

        Route.FormulaOne mSeason ->
            let
                season : Types.FormulaE.Season
                season =
                    mSeason
                        |> Maybe.withDefault Types.FormulaOne.currentSeason

                spec : { season : Types.FormulaOne.Season }
                spec =
                    { season = season }
            in
            ( { model
                | formulaOneLeaderboards =
                    Dict.insert season Helpers.Http.Inflight model.formulaOneLeaderboards
                , formulaOneEvents =
                    Dict.insert season Helpers.Http.Inflight model.formulaOneEvents
              }
            , Effect.Batch
                [ Effect.GetFormulaOneLeaderboard spec
                , Effect.GetFormulaOneSeasonLeaderboard spec
                , Effect.GetFormulaOneEvents spec
                , Effect.GetFormulaOneConstructorStandings spec
                , Effect.GetFormulaOneDriverStandings spec
                ]
            )

        Route.FormulaOneEvent season eventId ->
            let
                haveEventInfo : Bool
                haveEventInfo =
                    Dict.get season model.formulaOneEvents
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []
                        |> List.any (\event -> event.id == eventId)

                eventsEffect : Effect
                eventsEffect =
                    case haveEventInfo of
                        True ->
                            Effect.None

                        False ->
                            Effect.GetFormulaOneEvents { season = season }
            in
            ( model
            , Effect.Batch
                [ Effect.GetFormulaOneEventSessions { eventId = eventId }
                , eventsEffect
                ]
            )

        Route.FormulaOneSession season eventId sessionId ->
            let
                haveSessionInfo : Bool
                haveSessionInfo =
                    Dict.get eventId model.formulaOneSessions
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []
                        |> List.any (\session -> session.id == sessionId)

                haveEventInfo : Bool
                haveEventInfo =
                    Dict.get season model.formulaOneEvents
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []
                        |> List.any (\event -> event.id == eventId)
            in
            ( model
            , Effect.Batch
                [ Effect.GetFormulaOneEntrants { sessionId = sessionId }
                , Effect.GetFormulaOneSessionLeaderboard { sessionId = sessionId }
                , case haveSessionInfo of
                    True ->
                        Effect.None

                    False ->
                        Effect.GetFormulaOneEventSessions { eventId = eventId }
                , case haveEventInfo of
                    True ->
                        Effect.None

                    False ->
                        Effect.GetFormulaOneEvents { season = season }
                ]
            )

        Route.FormulaE mSeason ->
            let
                season : Types.FormulaE.Season
                season =
                    mSeason
                        |> Maybe.withDefault Types.FormulaE.currentSeason

                spec : { season : Types.FormulaE.Season }
                spec =
                    { season = season }
            in
            ( { model
                | formulaELeaderboards =
                    Dict.insert season Helpers.Http.Inflight model.formulaELeaderboards
                , formulaEEvents =
                    Dict.insert season Helpers.Http.Inflight model.formulaEEvents
              }
            , Effect.Batch
                [ Effect.GetFormulaELeaderboard spec
                , Effect.GetFormulaEEvents spec
                ]
            )

        Route.FormulaEEvent season eventId ->
            let
                haveEventInfo : Bool
                haveEventInfo =
                    Dict.get season model.formulaEEvents
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []
                        |> List.any (\event -> event.id == eventId)

                eventsEffect : Effect
                eventsEffect =
                    case haveEventInfo of
                        True ->
                            Effect.None

                        False ->
                            Effect.GetFormulaEEvents { season = season }

                spec : { eventId : Types.FormulaE.EventId }
                spec =
                    { eventId = eventId }
            in
            ( model
            , Effect.Batch
                [ eventsEffect
                , Effect.GetFormulaEEventEntrants spec
                , Effect.GetFormulaEEventLeaderboard spec
                ]
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

        Msg.Tick now ->
            Return.noEffect { model | now = now }

        Msg.GetTimeZone result ->
            case result of
                Err _ ->
                    ( model
                    , Effect.LegacyGetTimeZone
                    )

                Ok ( _, zone ) ->
                    Return.noEffect { model | zone = zone }

        Msg.LegacyGetTimeZone zone ->
            Return.noEffect { model | zone = zone }

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

        Msg.ReorderFormulaOneSessionPredictionEntry sessionId oldIndex newIndex ->
            let
                mCurrentOrder : Maybe (List Types.FormulaOne.Entrant)
                mCurrentOrder =
                    case Model.getFormulaOneCurrentSessionPrediction model sessionId of
                        Just order ->
                            Just order

                        Nothing ->
                            Dict.get sessionId model.formulaOneEntrants
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
            in
            case mCurrentOrder of
                Nothing ->
                    Return.noEffect model

                Just currentOrder ->
                    let
                        newOrder : List Types.FormulaOne.Entrant
                        newOrder =
                            Helpers.List.moveByIndex oldIndex newIndex currentOrder
                    in
                    Return.noEffect
                        { model
                            | formulaOneSessionPredictionEntries =
                                Dict.insert sessionId newOrder model.formulaOneSessionPredictionEntries
                        }

        Msg.ReorderFormulaOneSessionResultEntry sessionId oldIndex newIndex ->
            let
                mCurrentOrder : Maybe (List Types.FormulaOne.Entrant)
                mCurrentOrder =
                    case Model.getFormulaOneCurrentSessionResults model sessionId of
                        Just order ->
                            Just order

                        Nothing ->
                            Dict.get sessionId model.formulaOneEntrants
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
            in
            case mCurrentOrder of
                Nothing ->
                    Return.noEffect model

                Just currentOrder ->
                    let
                        newOrder : List Types.FormulaOne.Entrant
                        newOrder =
                            Helpers.List.moveByIndex oldIndex newIndex currentOrder
                    in
                    Return.noEffect
                        { model
                            | formulaOneSessionResultEntries =
                                Dict.insert sessionId newOrder model.formulaOneSessionResultEntries
                        }

        Msg.SubmitFormulaOneSessionEntry sessionId entrantIds ->
            ( { model
                | formulaOneSessionPredictionSubmitStatus =
                    Dict.insert sessionId Helpers.Http.Inflight model.formulaOneSessionPredictionSubmitStatus
              }
            , Effect.SubmitFormulaOneSessionPrediction { sessionId = sessionId } entrantIds
            )

        Msg.SubmitFormulaOneSessionEntryResponse sessionId result ->
            let
                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Prediction submitted successfully!"

                        Err _ ->
                            "Failed to submit prediction."
            in
            ( { model
                | formulaOneSessionPredictionSubmitStatus =
                    Dict.insert sessionId (Helpers.Http.fromResult result) model.formulaOneSessionPredictionSubmitStatus
              }
            , Effect.NativeAlert alertMessage
            )

        Msg.SubmitFormulaOneSessionResult sessionId entrantIds ->
            ( { model
                | formulaOneSessionResultSubmitStatus =
                    Dict.insert sessionId Helpers.Http.Inflight model.formulaOneSessionResultSubmitStatus
              }
            , Effect.SubmitFormulaOneSessionResult { sessionId = sessionId } entrantIds
            )

        Msg.SubmitFormulaOneSessionResultResponse sessionId result ->
            let
                newStatus : Helpers.Http.Status ()
                newStatus =
                    Helpers.Http.fromResult result
                        |> Helpers.Http.map (\_ -> ())

                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Result submitted successfully!"

                        Err _ ->
                            "Failed to submit result."
            in
            ( { model
                | formulaOneSessionResultSubmitStatus =
                    Dict.insert sessionId newStatus model.formulaOneSessionResultSubmitStatus
                , formulaOneSessionLeaderboards =
                    Dict.insert sessionId (Helpers.Http.fromResult result) model.formulaOneSessionLeaderboards
              }
            , Effect.NativeAlert alertMessage
            )

        Msg.FormulaOneLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneLeaderboards =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneLeaderboards
                }

        Msg.FormulaOneEventsResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneEvents =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneEvents
                }

        Msg.FormulaELeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaELeaderboards =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaELeaderboards
                }

        Msg.FormulaEEventsResponse spec result ->
            Return.noEffect
                { model
                    | formulaEEvents =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaEEvents
                }

        Msg.FormulaEEventEntrantsResponse spec result ->
            Return.noEffect
                { model
                    | formulaEEventEntrants =
                        Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaEEventEntrants
                }

        Msg.FormulaEEventLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaEEventLeaderboards =
                        Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaEEventLeaderboards
                }

        Msg.UpdateFormulaEPrediction spec updateMessage ->
            let
                prediction : Types.FormulaE.Prediction
                prediction =
                    case Helpers.Http.toMaybe model.userStatus of
                        Nothing ->
                            Types.FormulaE.emptyPrediction

                        Just user ->
                            Model.getFormulaEEventPrediction model user spec.eventId

                newPrediction : Types.FormulaE.Prediction
                newPrediction =
                    updateFormulaEPrediction updateMessage prediction
            in
            Return.noEffect
                { model
                    | formulaEPredictionInputs =
                        Dict.insert spec.eventId newPrediction model.formulaEPredictionInputs
                }

        Msg.UpdateFormulaEResult spec updateMessage ->
            let
                result : Types.FormulaE.Result
                result =
                    Model.getFormulaEEventResult model spec.eventId

                newResult : Types.FormulaE.Result
                newResult =
                    updateFormulaEPrediction updateMessage result
            in
            Return.noEffect
                { model
                    | formulaEResultInputs =
                        Dict.insert spec.eventId newResult model.formulaEResultInputs
                }

        Msg.SubmitFormulaEPrediction spec prediction ->
            ( { model
                | formulaEEventLeaderboards =
                    Dict.insert spec.eventId Helpers.Http.Inflight model.formulaEEventLeaderboards
              }
            , Effect.SubmitFormulaEPrediction spec prediction
            )

        Msg.SubmitFormulaEResult spec result ->
            ( { model
                | formulaEEventLeaderboards =
                    Dict.insert spec.eventId Helpers.Http.Inflight model.formulaEEventLeaderboards
              }
            , Effect.SubmitFormulaEResult spec result
            )

        Msg.SubmitFormulaEPredictionResponse spec result ->
            let
                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Prediction submitted successfully!"

                        Err _ ->
                            "Failed to submit prediction."
            in
            ( { model
                | formulaEEventLeaderboards =
                    Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaEEventLeaderboards
              }
            , Effect.NativeAlert alertMessage
            )

        Msg.SubmitFormulaEResultResponse spec result ->
            let
                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Result submitted successfully!"

                        Err _ ->
                            "Failed to submit result."
            in
            ( { model
                | formulaEEventLeaderboards =
                    Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaEEventLeaderboards
              }
            , Effect.NativeAlert alertMessage
            )

        Msg.FormulaOneEventSessionsResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneSessions =
                        Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaOneSessions
                }

        Msg.FormulaOneEntrantsResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneEntrants =
                        Dict.insert spec.sessionId (Helpers.Http.fromResult result) model.formulaOneEntrants
                }

        Msg.FormulaOneSessionLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneSessionLeaderboards =
                        Dict.insert spec.sessionId (Helpers.Http.fromResult result) model.formulaOneSessionLeaderboards
                }

        Msg.FormulaOneConstructorStandingsResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneConstructorStandings =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneConstructorStandings
                }

        Msg.FormulaOneSeasonLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneSeasonLeaderboards =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneSeasonLeaderboards
                }

        Msg.FormulaOneDriverStandingsResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneDriverStandings =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneDriverStandings
                }


updateFormulaEPrediction : Msg.UpdateFormulaEPredictionMsg -> Types.FormulaE.Prediction -> Types.FormulaE.Prediction
updateFormulaEPrediction msg prediction =
    case msg of
        Msg.SetPole entrantId ->
            { prediction | pole = entrantId }

        Msg.SetFam entrantId ->
            { prediction | fam = entrantId }

        Msg.SetFastestLap entrantId ->
            { prediction | fastestLap = entrantId }

        Msg.SetHgc entrantId ->
            { prediction | hgc = entrantId }

        Msg.SetFirst entrantId ->
            { prediction | first = entrantId }

        Msg.SetSecond entrantId ->
            { prediction | second = entrantId }

        Msg.SetThird entrantId ->
            { prediction | third = entrantId }

        Msg.SetFdnf entrantId ->
            { prediction | fdnf = entrantId }

        Msg.SetSafetyCar safetyCar ->
            { prediction | safetyCar = Just safetyCar }
