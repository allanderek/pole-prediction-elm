module Perform exposing (perform)

import Browser.Navigation
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Msg exposing (Msg)
import Types.FormulaE
import Types.FormulaOne
import Types.Leaderboard
import Types.Login
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

        Effect.GetFormulaOneLeaderboard spec ->
            Http.get
                { url = apiUrl [ "formula-one", "leaderboard", spec.season ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaOneLeaderboardResponse spec)
                        Types.Leaderboard.decoder
                }

        Effect.GetFormulaOneEvents spec ->
            Http.get
                { url = apiUrl [ "formula-one", "season-events", spec.season ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaOneEventsResponse spec)
                        (Decode.list Types.FormulaOne.eventDecoder)
                }

        Effect.GetFormulaOneEventSessions spec ->
            Http.get
                { url = apiUrl [ "formula-one", "event-sessions", String.fromInt spec.eventId ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaOneEventSessionsResponse spec)
                        (Decode.list Types.FormulaOne.sessionDecoder)
                }

        Effect.GetFormulaOneEntrants spec ->
            Http.get
                { url = apiUrl [ "formula-one", "session-entrants", String.fromInt spec.sessionId ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaOneEntrantsResponse spec)
                        (Decode.list Types.FormulaOne.entrantDecoder)
                }

        Effect.GetFormulaOneSessionLeaderboard spec ->
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

        Effect.GetFormulaOneSeasonLeaderboard spec ->
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

        Effect.GetFormulaOneConstructorStandings spec ->
            Http.get
                { url = apiUrl [ "formula-one", "constructor-standings", spec.season ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaOneConstructorStandingsResponse spec)
                        Types.Leaderboard.decoder
                }

        Effect.GetFormulaOneDriverStandings spec ->
            Http.get
                { url = apiUrl [ "formula-one", "driver-standings", spec.season ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaOneDriverStandingsResponse spec)
                        Types.Leaderboard.decoder
                }

        Effect.GetFormulaELeaderboard spec ->
            Http.get
                { url = apiUrl [ "formula-e", "leaderboard", spec.season ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaELeaderboardResponse spec)
                        Types.Leaderboard.decoder
                }

        Effect.GetFormulaEEvents spec ->
            Http.get
                { url = apiUrl [ "formula-e", "season-events", spec.season ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaEEventsResponse spec)
                        (Decode.list Types.FormulaE.eventDecoder)
                }

        Effect.GetFormulaEEventEntrants spec ->
            Http.get
                { url = apiUrl [ "formula-e", "event-entrants", String.fromInt spec.eventId ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaEEventEntrantsResponse spec)
                        (Decode.list Types.FormulaE.entrantDecoder)
                }

        Effect.GetFormulaEEventLeaderboard spec ->
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
