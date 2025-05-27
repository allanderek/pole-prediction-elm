module Components.FormulaOneEventInfo exposing (view)

import Components.FormulaOneSessionList
import Components.Info
import Components.Time
import Html exposing (Html)
import Model exposing (Model)
import Route
import Types.FormulaOne


type alias Config msg =
    { title : String
    , class : String
    , season : Types.FormulaOne.Season
    , start : List (Components.Info.Item msg)
    , eventId : Types.FormulaOne.EventId
    , mEvent : Maybe Types.FormulaOne.Event
    , mSessionId : Maybe Types.FormulaOne.SessionId
    }


view : Model key -> Config msg -> Html msg
view model config =
    let
        standardItems : List (Components.Info.Item msg)
        standardItems =
            [ { class = "event-round"
              , content =
                    case config.mEvent of
                        Nothing ->
                            Html.text "Unknown event"

                        Just event ->
                            String.fromInt event.round
                                |> String.append "Round: "
                                |> Html.text
              }
            , { class = "event-sessions"
              , content = Components.FormulaOneSessionList.view model config.eventId config.mSessionId
              }
            ]
    in
    Components.Info.view
        { title = config.title
        , class = config.class
        }
        (List.append config.start standardItems)
