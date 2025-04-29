module Main exposing
    ( ProgramFlags
    , main
    )

import Browser
import Browser.Navigation
import Effect exposing (Effect)
import Json.Decode as Decode
import Model exposing (Model)
import Msg exposing (Msg)
import Perform
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
            Sub.none
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
init _ url key =
    let
        initialModel : Model key
        initialModel =
            Model.initial key url
    in
    Update.initRoute initialModel
