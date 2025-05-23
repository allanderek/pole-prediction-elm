module Components.HttpStatus exposing
    ( Config
    , view
    )

import Helpers.Http
import Html exposing (Html)


type alias Config a msg =
    { viewFn : a -> Html msg
    , failedMessage : String
    }


view : Config a msg -> Helpers.Http.Status a -> Html msg
view config status =
    case status of
        Helpers.Http.Inflight ->
            Html.text "Loading..."

        Helpers.Http.Ready ->
            Html.text "Ready..."

        Helpers.Http.Failed _ ->
            Html.text config.failedMessage

        Helpers.Http.Succeeded data ->
            config.viewFn data
