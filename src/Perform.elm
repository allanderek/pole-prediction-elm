module Perform exposing (perform)

import Browser.Navigation
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)
import Msg exposing (Msg)
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

        Effect.GetFormulaELeaderboard spec ->
            Http.get
                { url = apiUrl [ "formula-e", "leaderboard", spec.season ]
                , expect =
                    Http.expectJson
                        (Msg.FormulaELeaderboardResponse spec)
                        Types.Leaderboard.decoder
                }
