module Perform exposing (perform)

import Browser.Navigation
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Msg exposing (Msg)
import Ports
import Task
import Time
import TimeZone
import Types.Data
import Types.FormulaE
import Types.FormulaOne
import Types.Leaderboard
import Types.Login
import Types.Profile
import Types.User exposing (User)


apiPrefix : String
apiPrefix =
    "/api"


apiUrl : List String -> String
apiUrl path =
    String.join "/" (apiPrefix :: path)


perform : { a | navigationKey : Browser.Navigation.Key } -> Effect -> Cmd Msg
perform model effect =
    case effect of
        Effect.None ->
            Cmd.none

        Effect.Batch effects ->
            List.map (perform model) effects
                |> Cmd.batch

        Effect.PushUrl url ->
            Browser.Navigation.pushUrl model.navigationKey url

        Effect.LoadUrl url ->
            Browser.Navigation.load url

        Effect.Reload ->
            Browser.Navigation.reload

        Effect.SetLocalStorage key value ->
            Ports.set_local_storage { key = key, value = value }

        Effect.ClearLocalStorage key ->
            Ports.clear_local_storage key

        Effect.NativeAlert message ->
            Ports.native_alert message

        Effect.GetTimeZone ->
            Task.attempt Msg.GetTimeZone TimeZone.getZone

        Effect.LegacyGetTimeZone ->
            Task.perform Msg.LegacyGetTimeZone Time.here

        Effect.SubmitLogin form ->
            let
                url : String
                url =
                    apiUrl [ "login" ]

                body : Http.Body
                body =
                    form
                        |> Types.Login.encodeForm
                        |> Http.jsonBody

                decoder : Decoder User
                decoder =
                    Types.User.decoder
                        |> Decode.field "user"
            in
            Http.post
                { url = url
                , body = body
                , expect = Http.expectJson Msg.LoginSubmitResponse decoder
                }

        Effect.SubmitLogout ->
            Http.post
                { url = apiUrl [ "logout" ]
                , body = Http.emptyBody
                , expect = Http.expectWhatever Msg.LogoutResponse
                }

        Effect.SubmitProfile form ->
            let
                decoder : Decoder User
                decoder =
                    Types.User.decoder
            in
            Http.post
                { url = apiUrl [ "profile" ]
                , body =
                    form
                        |> Types.Profile.encodeForm
                        |> Http.jsonBody
                , expect = Http.expectJson Msg.SubmitEditedProfileResponse decoder
                }

        Effect.GetData data ->
            case data of
                Types.Data.FormulaOneLeaderboard spec ->
                    Http.get
                        { url = apiUrl [ "formula-one", "leaderboard", spec.season ]
                        , expect =
                            Http.expectJson
                                (Msg.FormulaOneLeaderboardResponse spec)
                                Types.Leaderboard.decoder
                        }

                Types.Data.FormulaOneEvents spec ->
                    Http.get
                        { url = apiUrl [ "formula-one", "season-events", spec.season ]
                        , expect =
                            Http.expectJson
                                (Msg.FormulaOneEventsResponse spec)
                                (Decode.list Types.FormulaOne.eventDecoder)
                        }

                Types.Data.FormulaOneEventSessions spec ->
                    Http.get
                        { url = apiUrl [ "formula-one", "event-sessions", String.fromInt spec.eventId ]
                        , expect =
                            Http.expectJson
                                (Msg.FormulaOneEventSessionsResponse spec)
                                (Decode.list Types.FormulaOne.sessionDecoder)
                        }

                Types.Data.FormulaOneEntrants spec ->
                    Http.get
                        { url = apiUrl [ "formula-one", "session-entrants", String.fromInt spec.sessionId ]
                        , expect =
                            Http.expectJson
                                (Msg.FormulaOneEntrantsResponse spec)
                                (Decode.list Types.FormulaOne.entrantDecoder)
                        }

                Types.Data.FormulaOneSessionLeaderboard spec ->
                    let
                        decoder : Decoder Types.FormulaOne.SessionLeaderboard
                        decoder =
                            Decode.list Types.FormulaOne.scoredPredictionRowDecoder
                                |> Decode.map Types.FormulaOne.scoredPredictionRowsToSessionLeaderboard
                    in
                    Http.get
                        { url = apiUrl [ "formula-one", "session-leaderboard", String.fromInt spec.sessionId ]
                        , expect = Http.expectJson (Msg.FormulaOneSessionLeaderboardResponse spec) decoder
                        }

                Types.Data.FormulaOneSeasonLeaderboard spec ->
                    let
                        decoder : Decoder Types.FormulaOne.SeasonLeaderboard
                        decoder =
                            Decode.list Types.FormulaOne.seasonPredictionRowDecoder
                                |> Decode.map Types.FormulaOne.seasonLeaderboardFromSeasonPredictionRows
                    in
                    Http.get
                        { url = apiUrl [ "formula-one", "season-leaderboard", spec.season ]
                        , expect = Http.expectJson (Msg.FormulaOneSeasonLeaderboardResponse spec) decoder
                        }

                Types.Data.FormulaOneConstructorStandings spec ->
                    Http.get
                        { url = apiUrl [ "formula-one", "constructor-standings", spec.season ]
                        , expect =
                            Http.expectJson
                                (Msg.FormulaOneConstructorStandingsResponse spec)
                                Types.Leaderboard.decoder
                        }

                Types.Data.FormulaOneDriverStandings spec ->
                    Http.get
                        { url = apiUrl [ "formula-one", "driver-standings", spec.season ]
                        , expect =
                            Http.expectJson
                                (Msg.FormulaOneDriverStandingsResponse spec)
                                Types.Leaderboard.decoder
                        }

                Types.Data.FormulaELeaderboard spec ->
                    Http.get
                        { url = apiUrl [ "formula-e", "leaderboard", spec.season ]
                        , expect =
                            Http.expectJson
                                (Msg.FormulaELeaderboardResponse spec)
                                Types.Leaderboard.decoder
                        }

                Types.Data.FormulaEEvents spec ->
                    Http.get
                        { url = apiUrl [ "formula-e", "season-events", spec.season ]
                        , expect =
                            Http.expectJson
                                (Msg.FormulaEEventsResponse spec)
                                (Decode.list Types.FormulaE.eventDecoder)
                        }

                Types.Data.FormulaEEventEntrants spec ->
                    Http.get
                        { url = apiUrl [ "formula-e", "event-entrants", String.fromInt spec.eventId ]
                        , expect =
                            Http.expectJson
                                (Msg.FormulaEEventEntrantsResponse spec)
                                (Decode.list Types.FormulaE.entrantDecoder)
                        }

                Types.Data.FormulaEEventLeaderboard spec ->
                    Http.get
                        { url = apiUrl [ "formula-e", "race-predictions", String.fromInt spec.eventId ]
                        , expect = Http.expectJson (Msg.FormulaEEventLeaderboardResponse spec) Types.FormulaE.eventLeaderboardDecoder
                        }

        Effect.SubmitFormulaEPrediction spec prediction ->
            Http.post
                { url = apiUrl [ "formula-e", "race-prediction", String.fromInt spec.eventId ]
                , body =
                    Types.FormulaE.encodePrediction prediction
                        |> Http.jsonBody
                , expect = Http.expectJson (Msg.SubmitFormulaEPredictionResponse spec) Types.FormulaE.eventLeaderboardDecoder
                }

        Effect.SubmitFormulaEResult spec result ->
            Http.post
                { url = apiUrl [ "formula-e", "race-result", String.fromInt spec.eventId ]
                , body =
                    Types.FormulaE.encodePrediction result
                        |> Http.jsonBody
                , expect = Http.expectJson (Msg.SubmitFormulaEResultResponse spec) Types.FormulaE.eventLeaderboardDecoder
                }

        Effect.SubmitFormulaOneSessionPrediction spec entrantIds ->
            Http.post
                { url = apiUrl [ "formula-one", "session-prediction", String.fromInt spec.sessionId ]
                , body =
                    [ ( "positions", Encode.list Encode.int entrantIds ) ]
                        |> Encode.object
                        |> Http.jsonBody
                , expect =
                    Http.expectWhatever
                        (Msg.SubmitFormulaOneSessionEntryResponse spec.sessionId)
                }

        Effect.SubmitFormulaOneSessionResult spec entrantIds ->
            let
                decoder : Decoder Types.FormulaOne.SessionLeaderboard
                decoder =
                    Decode.list Types.FormulaOne.scoredPredictionRowDecoder
                        |> Decode.map Types.FormulaOne.scoredPredictionRowsToSessionLeaderboard
            in
            Http.post
                { url = apiUrl [ "formula-one", "session-result", String.fromInt spec.sessionId ]
                , body =
                    [ ( "positions", Encode.list Encode.int entrantIds ) ]
                        |> Encode.object
                        |> Http.jsonBody
                , expect =
                    Http.expectJson
                        (Msg.SubmitFormulaOneSessionResultResponse spec.sessionId)
                        decoder
                }
