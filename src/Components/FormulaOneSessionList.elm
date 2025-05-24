module Components.FormulaOneSessionList exposing (view)

import Components.HttpStatus
import Components.Time
import Dict
import Helpers.Classes
import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Model exposing (Model)
import Route
import Types.FormulaOne


view : Model key -> Types.FormulaOne.EventId -> Maybe Types.FormulaOne.SessionId -> Html msg
view model eventId mCurrentSessionId =
    let
        sessionsStatus : Helpers.Http.Status (List Types.FormulaOne.Session)
        sessionsStatus =
            Dict.get eventId model.formulaOneSessions
                |> Maybe.withDefault Helpers.Http.Ready

        withSessions : List Types.FormulaOne.Session -> Html msg
        withSessions sessions =
            let
                viewSession : Types.FormulaOne.Session -> Html msg
                viewSession session =
                    Html.li
                        []
                        [ Html.a
                            [ Attributes.class "session-link"
                            , Route.FormulaOneSession session.season eventId session.id
                                |> Route.href
                            , mCurrentSessionId
                                == Just session.id
                                |> Helpers.Classes.boolean "current-session" "not-current-session"
                            ]
                            [ Html.text session.name
                            , Html.text " - "
                            , Components.Time.shortFormat model.zone session.startTime
                            ]
                        ]
            in
            Html.ul
                []
                (List.map viewSession sessions)
    in
    Components.HttpStatus.view
        { viewFn = withSessions
        , failedMessage = "Error obtaining the sessions"
        }
        sessionsStatus
