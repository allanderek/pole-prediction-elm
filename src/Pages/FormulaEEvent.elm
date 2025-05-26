module Pages.FormulaEEvent exposing (view)

import Components.HttpStatus
import Components.Info
import Components.Login
import Components.Section
import Components.Selector
import Components.Time
import Dict
import Helpers.Attributes
import Helpers.Classes
import Helpers.Events
import Helpers.Http
import Helpers.List
import Helpers.Table
import Helpers.Time
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Extra
import Maybe.Extra
import Model exposing (Model)
import Msg exposing (Msg)
import Types.FormulaE
import Types.User exposing (User)


view : Model key -> Types.FormulaE.Event -> List (Html Msg)
view model event =
    let
        info : Html msg
        info =
            Components.Info.view
                { title = event.name
                , class = "formula-e-event-info"
                }
                [ { class = "event-country"
                  , content = Html.text event.country
                  }
                , { class = "event-circuit"
                  , content = Html.text event.circuit
                  }
                , { class = "event-date"
                  , content =
                        Html.div
                            []
                            [ Components.Time.longFormat model.zone event.startTime
                            , Html.text " - qualifying starts, and prediction entry closes"
                            ]
                  }
                ]

        mainContent : List (Html Msg)
        mainContent =
            case event.cancelled of
                True ->
                    [ Html.p
                        [ Helpers.Attributes.role "alert"
                        , Html.Attributes.class "event-cancelled"
                        ]
                        [ Html.text "This event has been cancelled." ]
                    ]

                False ->
                    let
                        entrantsStatus : Helpers.Http.Status (List Types.FormulaE.Entrant)
                        entrantsStatus =
                            Dict.get event.id model.formulaEEventEntrants
                                |> Maybe.withDefault Helpers.Http.Ready

                        mUser : Maybe User
                        mUser =
                            Helpers.Http.toMaybe model.userStatus

                        viewMain : List Types.FormulaE.Entrant -> List (Html Msg)
                        viewMain entrants =
                            case Helpers.Time.isEarlier model.now event.startTime of
                                True ->
                                    case mUser of
                                        Nothing ->
                                            [ Components.Login.youMustBeLoggedInTo "to make predictions" ]

                                        Just user ->
                                            [ viewInput model event.id user Prediction entrants ]

                                False ->
                                    let
                                        leaderboardStatus : Helpers.Http.Status Types.FormulaE.EventLeaderboard
                                        leaderboardStatus =
                                            Dict.get event.id model.formulaEEventLeaderboards
                                                |> Maybe.withDefault Helpers.Http.Ready

                                        viewLeaderboard : Html Msg
                                        viewLeaderboard =
                                            let
                                                withLeaderboard : Types.FormulaE.EventLeaderboard -> Html Msg
                                                withLeaderboard leaderboard =
                                                    let
                                                        viewRow : Types.FormulaE.ScoredPrediction -> Html Msg
                                                        viewRow scoredPrediction =
                                                            let
                                                                scoredAttribute : Bool -> Html.Attribute msg
                                                                scoredAttribute scored =
                                                                    Helpers.Classes.boolean "scored" "not-scored" scored

                                                                matchesResult : (Types.FormulaE.Prediction -> a) -> a -> Bool
                                                                matchesResult getResultValue predictionValue =
                                                                    leaderboard.result
                                                                        |> Maybe.map getResultValue
                                                                        |> Maybe.map ((==) predictionValue)
                                                                        |> Maybe.withDefault False

                                                                entrantCell : (Types.FormulaE.Prediction -> Types.FormulaE.EntrantId) -> Html Msg
                                                                entrantCell getEntrantId =
                                                                    let
                                                                        entrantId : Types.FormulaE.EntrantId
                                                                        entrantId =
                                                                            getEntrantId prediction
                                                                    in
                                                                    case Helpers.List.findWith entrantId .id entrants of
                                                                        Just entrant ->
                                                                            Html.div
                                                                                [ scoredAttribute <|
                                                                                    matchesResult getEntrantId entrantId
                                                                                ]
                                                                                [ Html.span
                                                                                    [ Html.Attributes.class "driver-name" ]
                                                                                    [ Html.text entrant.driver ]
                                                                                , Html.span
                                                                                    [ Html.Attributes.class "team-name" ]
                                                                                    [ Html.text entrant.teamShortName ]
                                                                                ]
                                                                                |> Helpers.Table.cell

                                                                        Nothing ->
                                                                            Helpers.Table.stringCell "Unknown - driver"

                                                                prediction : Types.FormulaE.Prediction
                                                                prediction =
                                                                    scoredPrediction.prediction

                                                                safetyCar : Html Msg
                                                                safetyCar =
                                                                    let
                                                                        value : String
                                                                        value =
                                                                            case prediction.safetyCar of
                                                                                Just True ->
                                                                                    "Yes"

                                                                                Just False ->
                                                                                    "No"

                                                                                Nothing ->
                                                                                    "-"

                                                                        scoresPoints : Bool
                                                                        scoresPoints =
                                                                            (prediction.safetyCar /= Nothing)
                                                                                && matchesResult .safetyCar prediction.safetyCar
                                                                    in
                                                                    Html.span
                                                                        [ scoredAttribute scoresPoints ]
                                                                        [ Html.text value ]
                                                                        |> Helpers.Table.cell
                                                            in
                                                            Html.tr
                                                                []
                                                                [ Helpers.Table.stringCell scoredPrediction.userName
                                                                , Helpers.Table.intCell scoredPrediction.score
                                                                , entrantCell .pole
                                                                , entrantCell .fam
                                                                , entrantCell .fastestLap
                                                                , entrantCell .hgc
                                                                , entrantCell .first
                                                                , entrantCell .second
                                                                , entrantCell .third
                                                                , entrantCell .fdnf
                                                                , safetyCar
                                                                ]
                                                    in
                                                    Html.div
                                                        [ Html.Attributes.class "table-wrapper" ]
                                                        [ Html.table
                                                            [ Html.Attributes.class "scores-table" ]
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
                                            Components.Section.view
                                                { title = "Session scores"
                                                , class = "formula-e-event-scores"
                                                }
                                                [ Components.HttpStatus.view
                                                    { viewFn = withLeaderboard
                                                    , failedMessage = "Error obtaining the event leaderboard"
                                                    }
                                                    leaderboardStatus
                                                ]
                                    in
                                    case mUser of
                                        Nothing ->
                                            [ viewLeaderboard ]

                                        Just user ->
                                            case user.isAdmin of
                                                False ->
                                                    [ viewLeaderboard ]

                                                True ->
                                                    [ viewInput model event.id user Result entrants
                                                    , viewLeaderboard
                                                    ]
                    in
                    Components.HttpStatus.viewList
                        { viewFn = viewMain
                        , failedMessage = "Error obtaining the event entrant information"
                        }
                        entrantsStatus
    in
    info :: mainContent


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

        invalidationMessage : Maybe String
        invalidationMessage =
            case kind of
                Result ->
                    Nothing

                Prediction ->
                    let
                        unselectedEntrantId : Types.FormulaE.EntrantId -> String -> Maybe String
                        unselectedEntrantId entrantId invalidation =
                            case entrantId == 0 of
                                True ->
                                    Just invalidation

                                False ->
                                    Nothing
                    in
                    Helpers.List.firstJust
                        [ unselectedEntrantId current.pole "Pole not selected"
                        , unselectedEntrantId current.fam "FAM not selected"
                        , unselectedEntrantId current.fastestLap "Fastest lap not selected"
                        , unselectedEntrantId current.hgc "HGC not selected"
                        , unselectedEntrantId current.first "First not selected"
                        , unselectedEntrantId current.second "Second not selected"
                        , case current.first == current.second of
                            True ->
                                Just "First and second cannot be the same"

                            False ->
                                Nothing
                        , unselectedEntrantId current.third "Third not selected"
                        , case current.first == current.third of
                            True ->
                                Just "First and third cannot be the same"

                            False ->
                                Nothing
                        , case current.second == current.third of
                            True ->
                                Just "Second and third cannot be the same"

                            False ->
                                Nothing
                        , unselectedEntrantId current.fdnf "FDNF not selected"
                        , case current.safetyCar of
                            Just True ->
                                Nothing

                            Just False ->
                                Nothing

                            Nothing ->
                                Just "Safety car not selected"
                        ]

        submitDisabled : Bool
        submitDisabled =
            Maybe.Extra.isJust invalidationMessage

        legend : Html msg
        legend =
            let
                text : String
                text =
                    case kind of
                        Prediction ->
                            "Prediction entry"

                        Result ->
                            "Result entry"
            in
            Html.legend
                []
                [ Html.text text ]

        fieldsetClass : Html.Attribute msg
        fieldsetClass =
            let
                className : String
                className =
                    case kind of
                        Prediction ->
                            "prediction-entry"

                        Result ->
                            "result-entry"
            in
            Html.Attributes.class className
    in
    Html.fieldset
        [ fieldsetClass ]
        [ legend
        , viewSelector { label = "Pole", current = current.pole, onInput = Msg.SetPole }
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
        , case invalidationMessage of
            Nothing ->
                Html.Extra.nothing

            Just message ->
                Html.div
                    [ Helpers.Attributes.role "alert"
                    , Html.Attributes.class "invalidation-message"
                    ]
                    [ Html.text message ]
        , Html.button
            [ Helpers.Events.onClickOrDisabled submitDisabled submitMessage ]
            [ Html.text "Submit" ]
        ]
