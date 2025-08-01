module Main exposing
    ( ProgramFlags
    , main
    )

import Browser
import Browser.Navigation
import Effect exposing (Effect)
import Helpers.Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Model exposing (Model)
import Msg exposing (Msg)
import Perform
import Ports
import Return
import Time
import Types.LocalStorageNotification
import Types.User exposing (User)
import Update
import Url
import View


type alias ProgramFlags =
    Decode.Value


main : Program ProgramFlags (Model Browser.Navigation.Key) Msg
main =
    let
        performEffect : ( Model Browser.Navigation.Key, Effect ) -> ( Model Browser.Navigation.Key, Cmd Msg )
        performEffect ( model, effect ) =
            ( model
            , Perform.perform model effect
            )

        performInit : ProgramFlags -> Url.Url -> Browser.Navigation.Key -> ( Model Browser.Navigation.Key, Cmd Msg )
        performInit flags url key =
            init flags url key
                |> performEffect

        performUpdate : Msg -> Model Browser.Navigation.Key -> ( Model Browser.Navigation.Key, Cmd Msg )
        performUpdate message model =
            Update.update message model
                |> performEffect

        subscriptions : Model key -> Sub Msg
        subscriptions _ =
            let
                tickSubscription : Sub Msg
                tickSubscription =
                    let
                        second : Float
                        second =
                            1000

                        tenSeconds : Float
                        tenSeconds =
                            second * 10
                    in
                    Time.every tenSeconds Msg.Tick

                localStorageChanged : Sub Msg
                localStorageChanged =
                    let
                        toMessage : Encode.Value -> Msg
                        toMessage jsonValue =
                            Decode.decodeValue Types.LocalStorageNotification.decoder jsonValue
                                |> Msg.LocalStorageNotification
                    in
                    Ports.local_storage_changed toMessage
            in
            Sub.batch
                [ tickSubscription
                , localStorageChanged
                ]
    in
    Browser.application
        { init = performInit
        , view = View.application
        , update = performUpdate
        , subscriptions = subscriptions
        , onUrlChange = Msg.UrlChanged
        , onUrlRequest = Msg.LinkClicked
        }


init : ProgramFlags -> Url.Url -> key -> ( Model key, Effect )
init programFlags url key =
    let
        decodeFlag : String -> Decoder a -> Result Decode.Error a
        decodeFlag fieldName fieldDecoder =
            Decode.decodeValue (Decode.field fieldName fieldDecoder) programFlags

        userStatus : Helpers.Http.Status User
        userStatus =
            case decodeFlag "user" Types.User.decoder of
                Ok user ->
                    Helpers.Http.Succeeded user

                Err _ ->
                    -- We do not use the Failed status for this since we would need
                    -- to translate the Decode.Error into an Http.Error, which could be done
                    -- but what would we do differently? In fact this is normal behaviour
                    -- if there *is* no user in the flags.
                    Helpers.Http.Ready

        now : Time.Posix
        now =
            decodeFlag "now" Decode.int
                |> Result.withDefault 0
                |> Time.millisToPosix

        initialModel : Model key
        initialModel =
            Model.initial key url now userStatus
    in
    Update.initRoute initialModel
        |> Return.addEffect Effect.GetTimeZone
