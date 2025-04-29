module Perform exposing (perform)

import Browser.Navigation
import Effect exposing (Effect)
import Msg exposing (Msg)


perform : { a | navigationKey : Browser.Navigation.Key } -> Effect -> Cmd Msg
perform model effect =
    case effect of
        Effect.None ->
            Cmd.none

        Effect.PushUrl url ->
            Browser.Navigation.pushUrl model.navigationKey url

        Effect.LoadUrl url ->
            Browser.Navigation.load url
