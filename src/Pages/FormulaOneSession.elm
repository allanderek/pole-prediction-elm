module Pages.FormulaOneSession exposing (view)

import Components.FormulaOneEventInfo
import Components.FormulaOneSessionEntry
import Components.HttpStatus
import Components.Login
import Components.Section
import Components.Time
import Components.UserName
import Dict
import Helpers.Http
import Helpers.List
import Helpers.Table
import Helpers.Time
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Html.Extra
import Model exposing (Model)
import Msg exposing (Msg)
import Route
import Time
import Types.FormulaOne


view : Model key -> Types.FormulaOne.Session -> List (Html Msg)
view model session =
    let
        navigationSection : Html msg
        navigationSection =
            let
                sortedEvents : List Types.FormulaOne.Event
                sortedEvents =
                    Model.getFromStatusDict session.season model.formulaOneEvents
                        |> Maybe.withDefault []
                        |> List.sortBy .round

                eventNav : { prev : Maybe Types.FormulaOne.Event, next : Maybe Types.FormulaOne.Event }
                eventNav =
                    Helpers.List.findPrevNext (\e -> e.id == session.eventId) sortedEvents

                sortedSessions : List Types.FormulaOne.Session
                sortedSessions =
                    Dict.get session.eventId model.formulaOneSessions
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []
                        |> List.sortBy (.startTime >> Time.posixToMillis)

                sessionNav : { prev : Maybe Types.FormulaOne.Session, next : Maybe Types.FormulaOne.Session }
                sessionNav =
                    Helpers.List.findPrevNext (\s -> s.id == session.id) sortedSessions

                viewPrevButton : Maybe a -> (a -> Route.Route) -> (a -> String) -> Html msg
                viewPrevButton mItem toRoute toLabel =
                    case mItem of
                        Nothing ->
                            Html.span
                                [ Attributes.class "page-nav-button page-nav-disabled" ]
                                [ Html.text "←" ]

                        Just item ->
                            Html.a
                                [ Attributes.class "page-nav-button"
                                , Route.href (toRoute item)
                                ]
                                [ Html.text ("← " ++ toLabel item) ]

                viewNextButton : Maybe a -> (a -> Route.Route) -> (a -> String) -> Html msg
                viewNextButton mItem toRoute toLabel =
                    case mItem of
                        Nothing ->
                            Html.span
                                [ Attributes.class "page-nav-button page-nav-disabled" ]
                                [ Html.text "→" ]

                        Just item ->
                            Html.a
                                [ Attributes.class "page-nav-button"
                                , Route.href (toRoute item)
                                ]
                                [ Html.text (toLabel item ++ " →") ]
            in
            Html.nav
                [ Attributes.class "page-navigation" ]
                [ Html.div
                    [ Attributes.class "page-nav-row" ]
                    [ viewPrevButton eventNav.prev (\e -> Route.FormulaOneEvent session.season e.id) Types.FormulaOne.eventName
                    , viewNextButton eventNav.next (\e -> Route.FormulaOneEvent session.season e.id) Types.FormulaOne.eventName
                    ]
                , Html.div
                    [ Attributes.class "page-nav-row" ]
                    [ viewPrevButton sessionNav.prev (\s -> Route.FormulaOneSession session.season session.eventId s.id) .name
                    , viewNextButton sessionNav.next (\s -> Route.FormulaOneSession session.season session.eventId s.id) .name
                    ]
                ]

        infoSection : Html msg
        infoSection =
            let
                mEvent : Maybe Types.FormulaOne.Event
                mEvent =
                    Model.getFromStatusDict session.season model.formulaOneEvents
                        |> Maybe.andThen (Helpers.List.findWith session.eventId .id)
            in
            Components.FormulaOneEventInfo.view
                model
                { title = session.name
                , class = "formula-one-session-info"
                , season = session.season
                , start =
                    [ { class = "session-start-time"
                      , content = Components.Time.longFormat model.zone session.startTime
                      }
                    , { class = "event-name"
                      , content =
                            Html.a
                                [ Route.FormulaOneEvent session.season session.eventId
                                    |> Route.href
                                ]
                                [ case mEvent of
                                    Nothing ->
                                        Html.text "Unknown event"

                                    Just event ->
                                        Types.FormulaOne.eventName event
                                            |> Html.text
                                ]
                      }
                    ]
                , eventId = session.eventId
                , mEvent = mEvent
                , mSessionId = Just session.id
                }

        viewPredictionEntry : List Types.FormulaOne.Entrant -> Html Msg
        viewPredictionEntry entrants =
            case Helpers.Http.toMaybe model.userStatus of
                Just user ->
                    -- TODO: Technically here we have to merge the entrants available with the current entry
                    let
                        currentPrediction : List Types.FormulaOne.Entrant
                        currentPrediction =
                            Model.getFormulaOneCurrentSessionPrediction model session.id
                                |> Maybe.withDefault entrants

                        mPrevSession : Maybe Types.FormulaOne.Session
                        mPrevSession =
                            Dict.get session.eventId model.formulaOneSessions
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
                                |> Maybe.withDefault []
                                |> List.sortBy (.startTime >> Time.posixToMillis)
                                |> Helpers.List.findPrevNext (\s -> s.id == session.id)
                                |> .prev

                        copyButtons : Html Msg
                        copyButtons =
                            case mPrevSession of
                                Nothing ->
                                    Html.Extra.nothing

                                Just prevSession ->
                                    let
                                        mPrevLeaderboard : Maybe Types.FormulaOne.SessionLeaderboard
                                        mPrevLeaderboard =
                                            Model.getFromStatusDict prevSession.id model.formulaOneSessionLeaderboards

                                        reorderFromPrev : List Types.FormulaOne.Entrant -> List Types.FormulaOne.Entrant
                                        reorderFromPrev prevOrder =
                                            let
                                                prevNumbers : List Int
                                                prevNumbers =
                                                    List.map .number prevOrder

                                                inPrevOrder : List Types.FormulaOne.Entrant
                                                inPrevOrder =
                                                    List.filterMap (\num -> Helpers.List.findWith num .number entrants) prevNumbers

                                                remaining : List Types.FormulaOne.Entrant
                                                remaining =
                                                    List.filter (\e -> not (List.member e.number prevNumbers)) entrants
                                            in
                                            inPrevOrder ++ remaining

                                        viewCopyButton : String -> Maybe (List Types.FormulaOne.Entrant) -> Html Msg
                                        viewCopyButton label mPrevEntrants =
                                            case mPrevEntrants of
                                                Nothing ->
                                                    Html.button
                                                        [ Attributes.type_ "button"
                                                        , Attributes.disabled True
                                                        , Attributes.class "copy-from-previous-button"
                                                        ]
                                                        [ Html.text label ]

                                                Just prevEntrants ->
                                                    Html.button
                                                        [ Attributes.type_ "button"
                                                        , Attributes.class "copy-from-previous-button"
                                                        , Events.onClick
                                                            (Msg.SetFormulaOneSessionPrediction session.id
                                                                (reorderFromPrev prevEntrants)
                                                            )
                                                        ]
                                                        [ Html.text label ]

                                        mPrevPrediction : Maybe (List Types.FormulaOne.Entrant)
                                        mPrevPrediction =
                                            case Dict.get prevSession.id model.formulaOneSessionPredictionEntries of
                                                Just entries ->
                                                    Just entries

                                                Nothing ->
                                                    mPrevLeaderboard
                                                        |> Maybe.andThen
                                                            (\lb ->
                                                                Helpers.List.findWith user.id .userId lb.predictions
                                                                    |> Maybe.map
                                                                        (.rows
                                                                            >> List.sortBy .predictedPosition
                                                                            >> List.map .entrant
                                                                        )
                                                            )

                                        mPrevResults : Maybe (List Types.FormulaOne.Entrant)
                                        mPrevResults =
                                            mPrevLeaderboard
                                                |> Maybe.andThen
                                                    (\lb ->
                                                        case lb.results of
                                                            [] ->
                                                                Nothing

                                                            results ->
                                                                Just results
                                                    )
                                    in
                                    Html.div
                                        [ Attributes.class "copy-from-previous-buttons" ]
                                        [ viewCopyButton "My previous prediction" mPrevPrediction
                                        , viewCopyButton "Previous results" mPrevResults
                                        ]
                    in
                    Components.Section.view
                        { title = "Prediction entry"
                        , class = "formula-one-session-prediction-entry"
                        }
                        [ copyButtons
                        , Components.FormulaOneSessionEntry.view
                            { kind = Components.FormulaOneSessionEntry.Prediction
                            , user = user
                            , entrants = currentPrediction
                            , reorderMessage = Msg.ReorderFormulaOneSessionPredictionEntry session.id
                            , submitMessage =
                                Msg.SubmitFormulaOneSessionEntry session.id
                                    (List.map .id currentPrediction)
                            }
                        ]

                Nothing ->
                    Components.Login.youMustBeLoggedInTo "make a prediction"

        viewIneditableResult : Maybe (List Types.FormulaOne.Entrant) -> Html Msg
        viewIneditableResult mCurrentResults =
            Components.Section.view
                { title = "Results"
                , class = "formula-one-session-results"
                }
                [ case mCurrentResults of
                    Nothing ->
                        Html.text "Waiting on results"

                    Just currentResults ->
                        let
                            viewRow : Int -> Types.FormulaOne.Entrant -> Html Msg
                            viewRow index entrant =
                                let
                                    position : Int
                                    position =
                                        index + 1

                                    driver : Html msg
                                    driver =
                                        Components.FormulaOneSessionEntry.viewEntrant
                                            { showPosition = False, withHandle = False }
                                            entrant
                                in
                                Html.tr
                                    []
                                    [ String.fromInt position
                                        |> Html.text
                                        |> Helpers.Table.cell
                                    , Helpers.Table.cell driver
                                    ]
                        in
                        Html.table
                            [ Attributes.class "formula-one-session-results-table" ]
                            [ Html.thead
                                []
                                [ Html.tr
                                    []
                                    [ Html.th [] [ Html.text "Position" ]
                                    , Html.th [] [ Html.text "Driver" ]
                                    ]
                                ]
                            , Html.tbody
                                []
                                (List.indexedMap viewRow currentResults)
                            ]
                ]

        viewResultEntry : List Types.FormulaOne.Entrant -> Html Msg
        viewResultEntry entrants =
            let
                mCurrentResults : Maybe (List Types.FormulaOne.Entrant)
                mCurrentResults =
                    Model.getFormulaOneCurrentSessionResults model session.id
            in
            case Helpers.Http.toMaybe model.userStatus of
                Nothing ->
                    viewIneditableResult mCurrentResults

                Just user ->
                    case user.isAdmin of
                        False ->
                            viewIneditableResult mCurrentResults

                        True ->
                            let
                                currentResults : List Types.FormulaOne.Entrant
                                currentResults =
                                    mCurrentResults
                                        |> Maybe.withDefault entrants
                            in
                            Components.Section.view
                                { title = "Results entry"
                                , class = "formula-one-session-results-entry"
                                }
                                [ Components.FormulaOneSessionEntry.view
                                    { kind = Components.FormulaOneSessionEntry.Result
                                    , user = user
                                    , entrants = currentResults
                                    , reorderMessage = Msg.ReorderFormulaOneSessionResultEntry session.id
                                    , submitMessage =
                                        Msg.SubmitFormulaOneSessionResult session.id
                                            (List.map .id currentResults)
                                    }
                                ]

        entrySection : Html Msg
        entrySection =
            let
                entrantsStatus : Helpers.Http.Status (List Types.FormulaOne.Entrant)
                entrantsStatus =
                    Dict.get session.id model.formulaOneEntrants
                        |> Maybe.withDefault Helpers.Http.Ready

                withEntrants : List Types.FormulaOne.Entrant -> Html Msg
                withEntrants entrants =
                    case Helpers.Time.isEarlier model.now session.startTime of
                        True ->
                            viewPredictionEntry entrants

                        False ->
                            viewResultEntry entrants
            in
            Components.HttpStatus.view
                { viewFn = withEntrants
                , failedMessage = "Error obtaining the details of the session entrants"
                }
                entrantsStatus

        leaderboardSection : Html Msg
        leaderboardSection =
            case Helpers.Time.isEarlier model.now session.startTime of
                True ->
                    Html.Extra.nothing

                False ->
                    let
                        leaderboardStatus : Helpers.Http.Status Types.FormulaOne.SessionLeaderboard
                        leaderboardStatus =
                            Dict.get session.id model.formulaOneSessionLeaderboards
                                |> Maybe.withDefault Helpers.Http.Ready

                        withLeaderboard : Types.FormulaOne.SessionLeaderboard -> Html Msg
                        withLeaderboard leaderboard =
                            let
                                viewRow : Types.FormulaOne.SessionLeaderboardRow -> Html Msg
                                viewRow leaderboardRow =
                                    let
                                        viewScoredRow : Types.FormulaOne.ScoredPredictionRow -> Html msg
                                        viewScoredRow scoredRow =
                                            let
                                                pointsClass : String
                                                pointsClass =
                                                    case scoredRow.score of
                                                        0 ->
                                                            "scored-row-zero"

                                                        4 ->
                                                            "scored-row-maximum"

                                                        _ ->
                                                            "scored-row-points"

                                                actualPosition : String
                                                actualPosition =
                                                    case scoredRow.actualPosition of
                                                        Just position ->
                                                            String.fromInt position

                                                        Nothing ->
                                                            "-"
                                            in
                                            Html.tr
                                                [ Attributes.class "scored-row"
                                                , Attributes.class pointsClass
                                                ]
                                                [ Html.td
                                                    [ Attributes.class "scored-row-position" ]
                                                    [ Html.text (String.fromInt scoredRow.predictedPosition) ]
                                                , Html.td
                                                    [ Attributes.class "scored-row-driver" ]
                                                    [ Html.text scoredRow.entrant.driver ]
                                                , Html.td
                                                    [ Attributes.class "scored-row-actual-position" ]
                                                    [ Html.text actualPosition ]
                                                , Html.td
                                                    [ Attributes.class "scored-row-score" ]
                                                    [ Html.text (String.fromInt scoredRow.score) ]
                                                ]

                                        scoredRows : List (Html msg)
                                        scoredRows =
                                            leaderboardRow.rows
                                                |> List.take 10
                                                |> List.map viewScoredRow
                                    in
                                    Html.li
                                        []
                                        [ Html.details
                                            []
                                            [ Html.summary
                                                []
                                                [ Html.span
                                                    [ Attributes.class "user-name" ]
                                                    [ Components.UserName.formulaOne
                                                        leaderboardRow.userId
                                                        leaderboardRow.userName
                                                    ]
                                                , Html.span
                                                    [ Attributes.class "total-score" ]
                                                    [ Html.text (String.fromInt leaderboardRow.total) ]
                                                ]
                                            , Html.table [] scoredRows
                                            ]
                                        ]
                            in
                            Components.Section.view
                                { title = "Leaderboard"
                                , class = "formula-one-session-leaderboard"
                                }
                                [ Html.ul [] (List.map viewRow leaderboard.predictions) ]
                    in
                    Components.HttpStatus.view
                        { viewFn = withLeaderboard
                        , failedMessage = "Error obtaining the session leaderboard"
                        }
                        leaderboardStatus
    in
    if session.cancelled then
        [ navigationSection
        , infoSection
        , Html.p
            [ Attributes.class "session-cancelled-notice" ]
            [ Html.text "This session has been cancelled." ]
        ]

    else
        [ navigationSection
        , infoSection
        , entrySection
        , leaderboardSection
        ]
