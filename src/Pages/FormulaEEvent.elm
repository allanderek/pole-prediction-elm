module Pages.FormulaEEvent exposing (view)

import Components.Selector
import Dict
import Helpers.Http
import Helpers.Time
import Html exposing (Html)
import Html.Attributes
import Html.Extra
import Model exposing (Model)
import Msg exposing (Msg)
import Types.FormulaE


view : Model key -> Types.FormulaE.Event -> List (Html Msg)
view model event =
    let
        info : Html msg
        info =
            Html.div
                [ Html.Attributes.class "formula-e-event" ]
                [ Html.h2
                    [ Html.Attributes.class "event-name" ]
                    [ Html.text event.name ]
                , Html.p
                    [ Html.Attributes.class "event-country" ]
                    [ Html.text event.country ]
                , Html.p
                    [ Html.Attributes.class "event-circuit" ]
                    [ Html.text event.circuit ]

                -- , Html.p
                --     [ Html.Attributes.class "event-date" ]
                --     [ Html.text (Time.toString event.date) ]
                ]

        viewEntrant : Types.FormulaE.Entrant -> Html Msg
        viewEntrant entrant =
            Html.li
                []
                [ Html.span
                    [ Html.Attributes.class "entrant-number" ]
                    [ Html.text (String.fromInt entrant.number) ]
                , Html.span
                    [ Html.Attributes.class "entrant-driver" ]
                    [ Html.text entrant.driver ]
                , Html.span
                    [ Html.Attributes.class "entrant-team" ]
                    [ Html.text entrant.teamShortName ]
                ]

        entrantsStatus : Helpers.Http.Status (List Types.FormulaE.Entrant)
        entrantsStatus =
            Dict.get event.id model.formulaEEventEntrants
                |> Maybe.withDefault Helpers.Http.Ready
    in
    [ info
    , case event.cancelled of
        True ->
            Html.div
                [ Html.Attributes.class "event-cancelled" ]
                [ Html.text "This event has been cancelled." ]

        False ->
            Html.div
                [ Html.Attributes.class "event-not-cancelled" ]
                [ Html.text "This event is not cancelled." ]
    , case entrantsStatus of
        Helpers.Http.Inflight ->
            Html.text "Loading..."

        Helpers.Http.Ready ->
            Html.text "Ready"

        Helpers.Http.Failed _ ->
            Html.text "Error obtaining the entrants"

        Helpers.Http.Succeeded entrants ->
            case Helpers.Http.toMaybe model.userStatus of
                Nothing ->
                    Html.text "Not logged in"

                Just user ->
                    case Helpers.Time.isEarlier model.now event.startTime of
                        True ->
                            viewInput model Prediction entrants

                        False ->
                            case user.isAdmin of
                                False ->
                                    Html.Extra.nothing

                                True ->
                                    viewInput model Result entrants
    ]


type InputKind
    = Prediction
    | Result


viewInput : Model key -> InputKind -> List Types.FormulaE.Entrant -> Html Msg
viewInput model kind entrants =
    let
        viewSelector : { current : Types.FormulaE.EntrantId } -> Html Msg
        viewSelector config =
            let
                options : List Components.Selector.Option
                options =
                    let
                        makeOption : Types.FormulaE.Entrant -> Components.Selector.Option
                        makeOption entrant =
                            { name = String.concat [ entrant.driver, " - ", entrant.teamShortName ]
                            , value = String.fromInt entrant.id
                            }
                    in
                    List.map makeOption entrants

                selectorConfig : Components.Selector.Config Msg
                selectorConfig =
                    { classPrefix = "formula-e-event-entrant"
                    , groups = Components.Selector.flatNoGroups options
                    , onInput = Msg.LoginIdentityInput
                    , onBlur = Nothing
                    , current = String.fromInt config.current
                    , disabled = False
                    , pleaseSelect = Just "Please select"
                    }
            in
            Components.Selector.view selectorConfig
    in
    viewSelector { current = 0 }
