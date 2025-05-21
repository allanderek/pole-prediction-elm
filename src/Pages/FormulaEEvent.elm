module Pages.FormulaEEvent exposing (view)

import Components.Selector
import Dict
import Helpers.Http
import Helpers.List
import Helpers.Table
import Helpers.Time
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Model exposing (Model)
import Msg exposing (Msg)
import Types.FormulaE
import Types.User exposing (User)


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
                            Html.div
                                []
                                [ Html.h3 [] [ Html.text "Prediction Entry" ]
                                , viewInput model event.id user Prediction entrants
                                ]

                        False ->
                            let
                                leaderboardStatus : Helpers.Http.Status Types.FormulaE.EventLeaderboard
                                leaderboardStatus =
                                    Dict.get event.id model.formulaEEventLeaderboards
                                        |> Maybe.withDefault Helpers.Http.Ready

                                viewLeaderboard : List (Html Msg)
                                viewLeaderboard =
                                    [ Html.h3 [] [ Html.text "Scores" ]
                                    , case leaderboardStatus of
                                        Helpers.Http.Inflight ->
                                            Html.text "Loading..."

                                        Helpers.Http.Ready ->
                                            Html.text "Ready"

                                        Helpers.Http.Failed _ ->
                                            Html.text "Error obtaining the leaderboard"

                                        Helpers.Http.Succeeded leaderboard ->
                                            let
                                                viewRow : Types.FormulaE.ScoredPrediction -> Html Msg
                                                viewRow scoredPrediction =
                                                    let
                                                        entrantCell : Types.FormulaE.EntrantId -> Html Msg
                                                        entrantCell entrantId =
                                                            case Helpers.List.findWith entrantId .id entrants of
                                                                Just entrant ->
                                                                    [ entrant.driver
                                                                    , " - "
                                                                    , entrant.teamShortName
                                                                    ]
                                                                        |> String.concat
                                                                        |> Html.text
                                                                        |> Helpers.Table.cell

                                                                Nothing ->
                                                                    Helpers.Table.stringCell "Unknown - driver"

                                                        prediction : Types.FormulaE.Prediction
                                                        prediction =
                                                            scoredPrediction.prediction
                                                    in
                                                    Html.tr
                                                        []
                                                        [ Helpers.Table.stringCell scoredPrediction.userName
                                                        , Helpers.Table.intCell scoredPrediction.score
                                                        , entrantCell prediction.pole
                                                        , entrantCell prediction.fam
                                                        , entrantCell prediction.fastestLap
                                                        , entrantCell prediction.hgc
                                                        , entrantCell prediction.first
                                                        , entrantCell prediction.second
                                                        , entrantCell prediction.third
                                                        , entrantCell prediction.fdnf
                                                        , Html.td
                                                            []
                                                            [ case prediction.safetyCar of
                                                                Just True ->
                                                                    Html.text "Yes"

                                                                Just False ->
                                                                    Html.text "No"

                                                                Nothing ->
                                                                    Html.text "-"
                                                            ]
                                                        ]
                                            in
                                            Html.table
                                                []
                                                [ Html.thead
                                                    []
                                                    [ Helpers.Table.headerRow
                                                        [ "User"
                                                        , "Score"
                                                        , "Pole"
                                                        , "FAM"
                                                        , "FL"
                                                        , "HGC"
                                                        , "First"
                                                        , "Second"
                                                        , "Third"
                                                        , "FDNF"
                                                        , "Safety car"
                                                        ]
                                                    ]
                                                , Html.tbody
                                                    []
                                                    (List.map viewRow leaderboard.predictions)
                                                ]
                                    ]
                            in
                            case user.isAdmin of
                                False ->
                                    Html.div
                                        []
                                        viewLeaderboard

                                True ->
                                    let
                                        resultsEntry : List (Html Msg)
                                        resultsEntry =
                                            [ Html.h3 [] [ Html.text "Results Entry" ]
                                            , viewInput model event.id user Result entrants
                                            ]
                                    in
                                    Html.div
                                        []
                                        (List.append resultsEntry viewLeaderboard)
    ]


type InputKind
    = Prediction
    | Result


type alias EntrantSelectorConfig =
    { label : String
    , current : Types.FormulaE.EntrantId
    , onInput : Types.FormulaE.EntrantId -> Msg.UpdateFormulaEPredictionMsg
    }


viewInput : Model key -> Types.FormulaE.EventId -> User -> InputKind -> List Types.FormulaE.Entrant -> Html Msg
viewInput model eventId user kind entrants =
    let
        spec : { eventId : Types.FormulaE.EventId }
        spec =
            { eventId = eventId }

        toMessage : Msg.UpdateFormulaEPredictionMsg -> Msg
        toMessage =
            case kind of
                Prediction ->
                    Msg.UpdateFormulaEPrediction spec

                Result ->
                    Msg.UpdateFormulaEResult spec

        submitMessage : Msg
        submitMessage =
            case kind of
                Prediction ->
                    Msg.SubmitFormulaEPrediction spec current

                Result ->
                    Msg.SubmitFormulaEResult spec current

        current : Types.FormulaE.Prediction
        current =
            case kind of
                Prediction ->
                    Model.getFormulaEEventPrediction model user eventId

                Result ->
                    Model.getFormulaEEventResult model eventId

        viewSelector : EntrantSelectorConfig -> Html Msg
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

                onInput : String -> Msg
                onInput valueString =
                    let
                        entrantId : Types.FormulaE.EntrantId
                        entrantId =
                            String.toInt valueString
                                |> Maybe.withDefault 0
                    in
                    config.onInput entrantId |> toMessage

                selectorConfig : Components.Selector.Config Msg
                selectorConfig =
                    { classPrefix = "formula-e-event-entrant"
                    , groups = Components.Selector.flatNoGroups options
                    , onInput = onInput
                    , onBlur = Nothing
                    , current = String.fromInt config.current
                    , disabled = False
                    , pleaseSelect = Just "Please select"
                    }
            in
            Html.div
                [ Html.Attributes.class "formula-e-event-entrant-selector" ]
                [ Html.label
                    []
                    [ Html.text config.label ]
                , Components.Selector.view selectorConfig
                ]

        safetyCarRadio : Bool -> Html Msg
        safetyCarRadio yes =
            Html.input
                [ Html.Attributes.type_ "radio"
                , Html.Attributes.name "safety_car"
                , Html.Attributes.checked (current.safetyCar == Just yes)
                , Msg.SetSafetyCar yes
                    |> toMessage
                    |> Html.Events.onClick
                ]
                []
    in
    Html.fieldset
        []
        [ viewSelector { label = "Pole", current = current.pole, onInput = Msg.SetPole }
        , viewSelector { label = "FAM", current = current.fam, onInput = Msg.SetFam }
        , viewSelector { label = "Fastest lap", current = current.fastestLap, onInput = Msg.SetFastestLap }
        , viewSelector { label = "HGC", current = current.hgc, onInput = Msg.SetHgc }
        , viewSelector { label = "First", current = current.first, onInput = Msg.SetFirst }
        , viewSelector { label = "Second", current = current.second, onInput = Msg.SetSecond }
        , viewSelector { label = "Third", current = current.third, onInput = Msg.SetThird }
        , viewSelector { label = "FDNF", current = current.fdnf, onInput = Msg.SetFdnf }
        , Html.div
            []
            [ Html.label [] [ Html.text "Safety car: " ]
            , Html.label
                []
                [ Html.text "no"
                , safetyCarRadio False
                ]
            , Html.label
                []
                [ safetyCarRadio True
                , Html.text "yes"
                ]
            ]
        , Html.button
            [ Html.Events.onClick submitMessage ]
            [ Html.text "Submit" ]
        ]
