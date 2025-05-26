module Components.HttpStatus exposing
    ( view
    , viewList
    )

import Helpers.Http
import Html exposing (Html)


type alias Config a b =
    { viewFn : a -> b
    , failedMessage : String
    }


viewList : Config a (List (Html msg)) -> Helpers.Http.Status a -> List (Html msg)
viewList config status =
    case status of
        Helpers.Http.Inflight ->
            [ Html.text "Loading..." ]

        Helpers.Http.Ready ->
            [ Html.text "Ready..." ]

        Helpers.Http.Failed _ ->
            [ Html.text config.failedMessage ]

        Helpers.Http.Succeeded data ->
            config.viewFn data


view : Config a (Html msg) -> Helpers.Http.Status a -> Html msg
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
