module Update exposing
    ( initRoute
    , update
    )

import Browser
import Dict exposing (Dict)
import Effect exposing (Effect)
import Helpers.Http
import Helpers.List
import Model exposing (Model)
import Msg exposing (Msg)
import Return
import Route exposing (Route)
import Types.Data exposing (Data)
import Types.FormulaE
import Types.FormulaOne
import Types.LocalStorageNotification
import Types.Login
import Types.OverUnder
import Types.Profile
import Types.Register
import Types.User exposing (User)
import Url


getData : Data -> Model key -> ( Model key, Effect )
getData data model =
    let
        newModel : Model key
        newModel =
            case data of
                Types.Data.FormulaOneLeaderboard spec ->
                    { model
                        | formulaOneLeaderboards =
                            Dict.insert spec.season Helpers.Http.Inflight model.formulaOneLeaderboards
                    }

                Types.Data.FormulaOneEvents spec ->
                    { model
                        | formulaOneEvents =
                            Dict.insert spec.season Helpers.Http.Inflight model.formulaOneEvents
                    }

                Types.Data.FormulaOneEventSessions spec ->
                    { model
                        | formulaOneSessions =
                            Dict.insert spec.eventId Helpers.Http.Inflight model.formulaOneSessions
                    }

                Types.Data.FormulaOneEntrants spec ->
                    { model
                        | formulaOneEntrants =
                            Dict.insert spec.sessionId Helpers.Http.Inflight model.formulaOneEntrants
                    }

                Types.Data.FormulaOneSessionLeaderboard spec ->
                    { model
                        | formulaOneSessionLeaderboards =
                            Dict.insert spec.sessionId Helpers.Http.Inflight model.formulaOneSessionLeaderboards
                    }

                Types.Data.FormulaOneSeasonLeaderboard spec ->
                    { model
                        | formulaOneSeasonLeaderboards =
                            Dict.insert spec.season Helpers.Http.Inflight model.formulaOneSeasonLeaderboards
                    }

                Types.Data.FormulaOneConcordantLeaderboard spec ->
                    { model
                        | formulaOneConcordantLeaderboards =
                            Dict.insert spec.season Helpers.Http.Inflight model.formulaOneConcordantLeaderboards
                    }

                Types.Data.FormulaOneConstructorStandings spec ->
                    { model
                        | formulaOneConstructorStandings =
                            Dict.insert spec.season Helpers.Http.Inflight model.formulaOneConstructorStandings
                    }

                Types.Data.FormulaOneDriverStandings spec ->
                    { model
                        | formulaOneDriverStandings =
                            Dict.insert spec.season Helpers.Http.Inflight model.formulaOneDriverStandings
                    }

                Types.Data.FormulaELeaderboard spec ->
                    { model
                        | formulaELeaderboards =
                            Dict.insert spec.season Helpers.Http.Inflight model.formulaELeaderboards
                    }

                Types.Data.FormulaEEvents spec ->
                    { model
                        | formulaEEvents =
                            Dict.insert spec.season Helpers.Http.Inflight model.formulaEEvents
                    }

                Types.Data.FormulaEEventEntrants spec ->
                    { model
                        | formulaEEventEntrants =
                            Dict.insert spec.eventId Helpers.Http.Inflight model.formulaEEventEntrants
                    }

                Types.Data.FormulaEEventLeaderboard spec ->
                    { model
                        | formulaEEventLeaderboards =
                            Dict.insert spec.eventId Helpers.Http.Inflight model.formulaEEventLeaderboards
                    }

                Types.Data.FormulaOneSeasonTeams spec ->
                    { model
                        | formulaOneSeasonTeams =
                            Dict.insert spec.season Helpers.Http.Inflight model.formulaOneSeasonTeams
                    }

                Types.Data.OverUnderCompetitions ->
                    { model | overUnderCompetitions = Helpers.Http.Inflight }

                Types.Data.OverUnderLeaderboard spec ->
                    { model
                        | overUnderLeaderboards =
                            Dict.insert spec.competitionId Helpers.Http.Inflight model.overUnderLeaderboards
                    }
    in
    ( newModel, Effect.GetData data )


{-| The page decides what to draw from our own clock, so it changes over the moment the
deadline passes rather than waiting for a round trip. But the leaderboard we are holding
was built by the server against _its_ clock, so when our clock says entry has closed and
the leaderboard still says it was open, what we have is the empty pre-deadline one and we
ask again.

The two clocks never have to agree, they only have to converge. If ours runs ahead we
re-ask each tick until the server catches up. If ours runs behind, the entry buttons
linger for a moment and a submit in that window is refused by the server, which we
already report.

A request that failed counts as not having one, so a leaderboard that could not be
fetched is asked for again on the next tick. Without that, one unlucky request left the
results reading 'Error obtaining the leaderboard' for as long as the page stayed open,
which is the very situation a retry is for.

Only while actually looking at that competition, so this never polls in the background,
and it stops as soon as the server agrees entry has closed. While a request is in flight
we do not send another, so a slow response cannot pile them up.

Note this is about not having the data. Data we have but which the server has since
changed, such as a current probability being updated, is a separate question and is not
handled here.

-}
overUnderLeaderboardToRefetch : Model key -> Maybe Types.OverUnder.CompetitionId
overUnderLeaderboardToRefetch model =
    case model.route of
        Route.OverUnderCompetition competitionId ->
            let
                weSayClosed : Bool
                weSayClosed =
                    Helpers.Http.toMaybe model.overUnderCompetitions
                        |> Maybe.withDefault []
                        |> Helpers.List.findWith competitionId .id
                        |> Maybe.map (Types.OverUnder.deadlinePassed model.now)
                        |> Maybe.withDefault False

                -- Whether we still need to ask for the leaderboard. Every case is
                -- written out rather than gathered under a catch-all, both because
                -- each one wants saying and so that adding a state to
                -- Helpers.Http.Status makes the compiler ask about this decision
                -- rather than quietly folding it in with the others.
                needLeaderboard : Bool
                needLeaderboard =
                    case Dict.get competitionId model.overUnderLeaderboards of
                        Nothing ->
                            -- Never asked. initRoute does ask on the way in, so this
                            -- should not arise, but if it ever does then asking is
                            -- the right answer.
                            True

                        Just Helpers.Http.Ready ->
                            -- Same as never having asked.
                            True

                        Just Helpers.Http.Inflight ->
                            -- One is already on its way. Asking again every tick
                            -- would pile them up.
                            False

                        Just (Helpers.Http.Failed _) ->
                            -- The case the retry exists for. Giving up here left the
                            -- results reading 'Error obtaining the leaderboard' for
                            -- as long as the page stayed open.
                            True

                        Just (Helpers.Http.Succeeded leaderboard) ->
                            -- We have one, but it is the empty pre-deadline
                            -- leaderboard if the server still thought entry was open.
                            not leaderboard.serverDeadlinePassed
            in
            case weSayClosed && needLeaderboard of
                True ->
                    Just competitionId

                False ->
                    Nothing

        _ ->
            Nothing


getDataWith : Data -> ( Model key, Effect ) -> ( Model key, Effect )
getDataWith data ( model, existingEffect ) =
    Return.combine (getData data) ( model, existingEffect )


getMultipleData : List Data -> Model key -> ( Model key, Effect )
getMultipleData datas model =
    List.foldl getDataWith (Return.noEffect model) datas


getMultipleDataIf : List ( Bool, Data ) -> Model key -> ( Model key, Effect )
getMultipleDataIf datas model =
    getMultipleData (Helpers.List.filterByFirst datas) model


initRoute : Model key -> ( Model key, Effect )
initRoute model =
    case model.route of
        Route.Home ->
            Return.noEffect model

        Route.Login ->
            Return.noEffect model

        Route.Register ->
            Return.noEffect model

        Route.FormulaOne mSeason ->
            let
                season : Types.FormulaOne.Season
                season =
                    mSeason
                        |> Maybe.withDefault Types.FormulaOne.currentSeason

                spec : { season : Types.FormulaOne.Season }
                spec =
                    { season = season }
            in
            model
                |> getMultipleData
                    [ Types.Data.FormulaOneLeaderboard spec
                    , Types.Data.FormulaOneConcordantLeaderboard spec
                    , Types.Data.FormulaOneSeasonLeaderboard spec
                    , Types.Data.FormulaOneEvents spec
                    , Types.Data.FormulaOneConstructorStandings spec
                    , Types.Data.FormulaOneDriverStandings spec
                    , Types.Data.FormulaOneSeasonTeams spec
                    ]

        Route.FormulaOneEvent season eventId ->
            let
                haveEventInfo : Bool
                haveEventInfo =
                    Dict.get season model.formulaOneEvents
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []
                        |> List.any (\event -> event.id == eventId)
            in
            model
                |> getMultipleDataIf
                    [ ( not haveEventInfo, Types.Data.FormulaOneEvents { season = season } )
                    , ( True, Types.Data.FormulaOneEventSessions { eventId = eventId } )
                    ]

        Route.FormulaOneSession season eventId sessionId ->
            let
                sessions : List Types.FormulaOne.Session
                sessions =
                    Dict.get eventId model.formulaOneSessions
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []

                haveSessionInfo : Bool
                haveSessionInfo =
                    List.any (\s -> s.id == sessionId) sessions

                haveEventInfo : Bool
                haveEventInfo =
                    Dict.get season model.formulaOneEvents
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []
                        |> List.any (\event -> event.id == eventId)

                mPrevSessionId : Maybe Types.FormulaOne.SessionId
                mPrevSessionId =
                    (Helpers.List.findPrevNext (\s -> s.id == sessionId) sessions).prev
                        |> Maybe.map .id

                prevLeaderboardFetch : List ( Bool, Data )
                prevLeaderboardFetch =
                    case mPrevSessionId of
                        Nothing ->
                            []

                        Just prevSessionId ->
                            [ ( not (Dict.member prevSessionId model.formulaOneSessionLeaderboards)
                              , Types.Data.FormulaOneSessionLeaderboard { sessionId = prevSessionId }
                              )
                            ]
            in
            model
                |> getMultipleDataIf
                    ([ ( True, Types.Data.FormulaOneEntrants { sessionId = sessionId } )
                     , ( True, Types.Data.FormulaOneSessionLeaderboard { sessionId = sessionId } )
                     , ( not haveSessionInfo
                       , Types.Data.FormulaOneEventSessions { eventId = eventId }
                       )
                     , ( not haveEventInfo
                       , Types.Data.FormulaOneEvents { season = season }
                       )
                     ]
                        ++ prevLeaderboardFetch
                    )

        Route.FormulaE mSeason ->
            let
                season : Types.FormulaE.Season
                season =
                    mSeason
                        |> Maybe.withDefault Types.FormulaE.currentSeason

                spec : { season : Types.FormulaE.Season }
                spec =
                    { season = season }
            in
            model
                |> getMultipleData
                    [ Types.Data.FormulaELeaderboard spec
                    , Types.Data.FormulaEEvents spec
                    ]

        Route.FormulaEEvent season eventId ->
            let
                haveEventInfo : Bool
                haveEventInfo =
                    Dict.get season model.formulaEEvents
                        |> Maybe.withDefault Helpers.Http.Ready
                        |> Helpers.Http.toMaybe
                        |> Maybe.withDefault []
                        |> List.any (\event -> event.id == eventId)

                spec : { eventId : Types.FormulaE.EventId }
                spec =
                    { eventId = eventId }
            in
            model
                |> getMultipleDataIf
                    [ ( not haveEventInfo
                      , Types.Data.FormulaEEvents { season = season }
                      )
                    , ( True
                      , Types.Data.FormulaEEventEntrants spec
                      )
                    , ( True
                      , Types.Data.FormulaEEventLeaderboard spec
                      )
                    ]

        Route.OverUnder ->
            getData Types.Data.OverUnderCompetitions model

        Route.OverUnderCompetition competitionId ->
            let
                haveCompetitions : Bool
                haveCompetitions =
                    case model.overUnderCompetitions of
                        Helpers.Http.Succeeded _ ->
                            True

                        _ ->
                            False
            in
            -- One endpoint serves both pages, so coming here from the list of
            -- competitions does not need to fetch the competitions again.
            model
                |> getMultipleDataIf
                    [ ( not haveCompetitions
                      , Types.Data.OverUnderCompetitions
                      )
                    , ( True
                      , Types.Data.OverUnderLeaderboard { competitionId = competitionId }
                      )
                    ]

        Route.Profile ->
            Return.noEffect model

        Route.NotFound ->
            Return.noEffect model


logoutUser : { clearLocalStorage : Bool } -> Model key -> ( Model key, Effect )
logoutUser config model =
    -- It doesn't really matter what the result is, since even with success
    -- we're just going to reload the current page, so any updates we do here would
    -- be lost anyway. If this fails, then we could set the user status to the failure,
    -- but then that would look like you were logged-out when maybe actually you weren't.
    -- So we just ignore the result and reload the page.
    ( model
    , Effect.Batch
        [ Effect.Reload

        -- Note: This is second so that it occurs first, that is how Cmd.batch works.
        , case config.clearLocalStorage of
            True ->
                Effect.ClearLocalStorage "user"

            False ->
                Effect.None
        ]
    )


{-| The user has logged in on a separate tab, so everything we have already fetched was
fetched as somebody else. Several endpoints answer differently depending on who is
asking, and the season leaderboard returns no rows at all to an anonymous reader before
its deadline, so what is on screen is not merely incomplete but wrong.

Rather than try to keep a list of which data is user-dependent, we load the page afresh,
which is what logging out on another tab already does. A list would be a fix that decays,
since the next person to add a conditional fetch has no reason to think of this.

This is deliberately a single effect rather than a reload batched with a navigation.
Those two race, and Cmd.batch promises no order. Browser.Navigation.load both navigates
and loads afresh, so there is nothing to race.

-}
otherTabLoginNav : Route -> Effect
otherTabLoginNav route =
    case route of
        Route.Login ->
            Route.unparse Route.Home
                |> Effect.LoadUrl

        Route.Register ->
            Route.unparse Route.Home
                |> Effect.LoadUrl

        _ ->
            Effect.Reload


postLoginNav : Route -> Effect
postLoginNav route =
    case route of
        Route.Login ->
            Effect.goto Route.Home

        Route.Register ->
            Effect.goto Route.Home

        _ ->
            Effect.None


update : Msg -> Model key -> ( Model key, Effect )
update msg model =
    case msg of
        Msg.LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    let
                        urlString : String
                        urlString =
                            Url.toString url
                    in
                    -- The Google OAuth link is a same-domain path (/api/auth/google/login)
                    -- so Elm intercepts it as "internal". We need a full browser redirect.
                    case url.path == Route.googleOAuthPath of
                        True ->
                            ( model, Effect.LoadUrl urlString )

                        False ->
                            ( model, Effect.PushUrl urlString )

                Browser.External href ->
                    ( model
                    , Effect.LoadUrl href
                    )

        Msg.UrlChanged url ->
            initRoute
                { model | route = Route.parse url }

        Msg.Tick now ->
            let
                tickedModel : Model key
                tickedModel =
                    { model | now = now }
            in
            case overUnderLeaderboardToRefetch tickedModel of
                Nothing ->
                    Return.noEffect tickedModel

                Just competitionId ->
                    getData
                        (Types.Data.OverUnderLeaderboard { competitionId = competitionId })
                        tickedModel

        Msg.GetTimeZone result ->
            case result of
                Err _ ->
                    ( model
                    , Effect.LegacyGetTimeZone
                    )

                Ok ( _, zone ) ->
                    Return.noEffect { model | zone = zone }

        Msg.LegacyGetTimeZone zone ->
            Return.noEffect { model | zone = zone }

        Msg.LocalStorageNotification result ->
            case result of
                Err _ ->
                    -- This could of course mean there is an error in the decoder, in normal operation it
                    -- simply means that it was a local storage key we do not care about.
                    Return.noEffect model

                Ok (Types.LocalStorageNotification.UserUpdated mNewUser) ->
                    let
                        mCurrentUser : Maybe User
                        mCurrentUser =
                            Helpers.Http.toMaybe model.userStatus
                    in
                    case ( mCurrentUser, mNewUser ) of
                        ( Just _, Nothing ) ->
                            -- The user has logged-out on a separate tab.
                            logoutUser { clearLocalStorage = False } model

                        ( Just currentUser, Just newUser ) ->
                            case currentUser.id == newUser.id of
                                False ->
                                    -- Somebody else has logged in on another tab. As
                                    -- far as the data we are holding is concerned this
                                    -- is no different from having been logged out: all
                                    -- of it was fetched as the previous user.
                                    ( model
                                    , otherTabLoginNav model.route
                                    )

                                True ->
                                    -- The same person, so only their details have
                                    -- changed. That is a profile edit, or a token
                                    -- refresh which does not alter this record at all.
                                    -- Nothing we have fetched has gone stale, so we
                                    -- keep it and simply take the new details.
                                    Return.noEffect
                                        { model | userStatus = Helpers.Http.Succeeded newUser }

                        ( Nothing, Just _ ) ->
                            -- The user has been logged-in on a separate tab. As with
                            -- logging out on another tab, we do not bother updating
                            -- the model, since we are about to load the page afresh
                            -- and anything we set here would be thrown away with it.
                            ( model
                            , otherTabLoginNav model.route
                            )

                        ( Nothing, Nothing ) ->
                            -- Unlikely, but whatever this means that the user has been logged-out but this application
                            -- already thinks the user is logged-out so nothing to do.
                            Return.noEffect model

        Msg.LoginIdentityInput input ->
            let
                form : Types.Login.Form
                form =
                    model.loginForm
            in
            Return.noEffect
                { model | loginForm = { form | username = input } }

        Msg.LoginPasswordInput input ->
            let
                form : Types.Login.Form
                form =
                    model.loginForm
            in
            Return.noEffect
                { model | loginForm = { form | password = input } }

        Msg.LoginSubmit ->
            case Types.Login.isValidForm model.loginForm of
                False ->
                    Return.noEffect model

                True ->
                    ( { model | userStatus = Helpers.Http.Inflight }
                    , Effect.SubmitLogin model.loginForm
                    )

        Msg.LoginSubmitResponse result ->
            ( { model | userStatus = Helpers.Http.fromResult result }
            , case result of
                Err _ ->
                    Effect.NativeAlert "Login failed. Please check your username and password."

                Ok user ->
                    Effect.Batch
                        [ postLoginNav model.route
                        , Effect.SetLocalStorage "user" (Types.User.encode user)
                        ]
            )

        Msg.RegisterUsernameInput input ->
            let
                form : Types.Register.Form
                form =
                    model.registerForm
            in
            Return.noEffect { model | registerForm = { form | username = input } }

        Msg.RegisterPasswordInput input ->
            let
                form : Types.Register.Form
                form =
                    model.registerForm
            in
            Return.noEffect { model | registerForm = { form | password = input } }

        Msg.RegisterEmailInput input ->
            let
                form : Types.Register.Form
                form =
                    model.registerForm
            in
            Return.noEffect { model | registerForm = { form | email = input } }

        Msg.RegisterFullNameInput input ->
            let
                form : Types.Register.Form
                form =
                    model.registerForm
            in
            Return.noEffect { model | registerForm = { form | fullName = input } }

        Msg.RegisterSubmit ->
            case Types.Register.isValidForm model.registerForm of
                False ->
                    Return.noEffect model

                True ->
                    ( { model | userStatus = Helpers.Http.Inflight }
                    , Effect.SubmitRegister model.registerForm
                    )

        Msg.RegisterSubmitResponse result ->
            ( { model | userStatus = Helpers.Http.fromResult result }
            , case result of
                Err _ ->
                    Effect.NativeAlert "Registration failed. The username may already be taken."

                Ok user ->
                    Effect.Batch
                        [ postLoginNav model.route
                        , Effect.SetLocalStorage "user" (Types.User.encode user)
                        ]
            )

        Msg.Logout ->
            ( model, Effect.SubmitLogout )

        Msg.LogoutResponse result ->
            let
                clearLocalStorage : Bool
                clearLocalStorage =
                    case result of
                        Ok _ ->
                            True

                        Err _ ->
                            False
            in
            -- We don't care about the result of the logout since we're about to reload the page anyway.
            -- If the logout was successful, this will logout the user, if it failed, then the user will
            -- still be logged-in after the reload. However, we do want to clear the local storage only if
            -- the logout was successful.
            logoutUser { clearLocalStorage = clearLocalStorage } model

        Msg.EditProfile ->
            Return.noEffect { model | editingProfile = True }

        Msg.CancelEditProfile ->
            Return.noEffect { model | editingProfile = False }

        Msg.EditProfileFullNameInput input ->
            case Helpers.Http.toMaybe model.userStatus of
                Nothing ->
                    Return.noEffect model

                Just user ->
                    let
                        newForm : Maybe Types.Profile.Form
                        newForm =
                            case input == user.fullname of
                                True ->
                                    Nothing

                                False ->
                                    let
                                        form : Types.Profile.Form
                                        form =
                                            case model.profileForm of
                                                Nothing ->
                                                    Types.Profile.initForm user

                                                Just existingForm ->
                                                    existingForm
                                    in
                                    Just { form | fullname = input }
                    in
                    Return.noEffect
                        { model | profileForm = newForm }

        Msg.SubmitEditedProfile form ->
            ( { model | profileStatus = Helpers.Http.Inflight }
            , Effect.SubmitProfile form
            )

        Msg.SubmitEditedProfileResponse result ->
            ( { model
                | profileStatus = Helpers.Http.fromResult result
                , userStatus =
                    case result of
                        Ok user ->
                            Helpers.Http.Succeeded user

                        Err _ ->
                            model.userStatus
                , editingProfile =
                    case result of
                        Ok _ ->
                            False

                        Err _ ->
                            True
                , profileForm =
                    case result of
                        Ok _ ->
                            Nothing

                        Err _ ->
                            model.profileForm
              }
            , case result of
                Ok user ->
                    Effect.SetLocalStorage "user" (Types.User.encode user)

                Err _ ->
                    Effect.None
            )

        Msg.SetFormulaOneSessionPrediction sessionId entrants ->
            Return.noEffect
                { model
                    | formulaOneSessionPredictionEntries =
                        Dict.insert sessionId entrants model.formulaOneSessionPredictionEntries
                }

        Msg.ReorderFormulaOneSessionPredictionEntry sessionId oldIndex newIndex ->
            let
                mCurrentOrder : Maybe (List Types.FormulaOne.Entrant)
                mCurrentOrder =
                    case Model.getFormulaOneCurrentSessionPrediction model sessionId of
                        Just order ->
                            Just order

                        Nothing ->
                            Dict.get sessionId model.formulaOneEntrants
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
            in
            case mCurrentOrder of
                Nothing ->
                    Return.noEffect model

                Just currentOrder ->
                    let
                        newOrder : List Types.FormulaOne.Entrant
                        newOrder =
                            Helpers.List.moveByIndex oldIndex newIndex currentOrder
                    in
                    Return.noEffect
                        { model
                            | formulaOneSessionPredictionEntries =
                                Dict.insert sessionId newOrder model.formulaOneSessionPredictionEntries
                        }

        Msg.ReorderFormulaOneSessionResultEntry sessionId oldIndex newIndex ->
            let
                mCurrentOrder : Maybe (List Types.FormulaOne.Entrant)
                mCurrentOrder =
                    case Model.getFormulaOneCurrentSessionResults model sessionId of
                        Just order ->
                            Just order

                        Nothing ->
                            Dict.get sessionId model.formulaOneEntrants
                                |> Maybe.withDefault Helpers.Http.Ready
                                |> Helpers.Http.toMaybe
            in
            case mCurrentOrder of
                Nothing ->
                    Return.noEffect model

                Just currentOrder ->
                    let
                        newOrder : List Types.FormulaOne.Entrant
                        newOrder =
                            Helpers.List.moveByIndex oldIndex newIndex currentOrder
                    in
                    Return.noEffect
                        { model
                            | formulaOneSessionResultEntries =
                                Dict.insert sessionId newOrder model.formulaOneSessionResultEntries
                        }

        Msg.SubmitFormulaOneSessionEntry sessionId entrantIds ->
            ( { model
                | formulaOneSessionPredictionSubmitStatus =
                    Dict.insert sessionId Helpers.Http.Inflight model.formulaOneSessionPredictionSubmitStatus
              }
            , Effect.SubmitFormulaOneSessionPrediction { sessionId = sessionId } entrantIds
            )

        Msg.SubmitFormulaOneSessionEntryResponse sessionId result ->
            let
                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Prediction submitted successfully!"

                        Err _ ->
                            "Failed to submit prediction."
            in
            ( { model
                | formulaOneSessionPredictionSubmitStatus =
                    Dict.insert sessionId (Helpers.Http.fromResult result) model.formulaOneSessionPredictionSubmitStatus
              }
            , Effect.NativeAlert alertMessage
            )

        Msg.SubmitFormulaOneSessionResult sessionId entrantIds ->
            ( { model
                | formulaOneSessionResultSubmitStatus =
                    Dict.insert sessionId Helpers.Http.Inflight model.formulaOneSessionResultSubmitStatus
              }
            , Effect.SubmitFormulaOneSessionResult { sessionId = sessionId } entrantIds
            )

        Msg.SubmitFormulaOneSessionResultResponse sessionId result ->
            let
                newStatus : Helpers.Http.Status ()
                newStatus =
                    Helpers.Http.fromResult result
                        |> Helpers.Http.map (\_ -> ())

                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Result submitted successfully!"

                        Err _ ->
                            "Failed to submit result."
            in
            ( { model
                | formulaOneSessionResultSubmitStatus =
                    Dict.insert sessionId newStatus model.formulaOneSessionResultSubmitStatus
                , formulaOneSessionLeaderboards =
                    Dict.insert sessionId (Helpers.Http.fromResult result) model.formulaOneSessionLeaderboards
              }
            , Effect.NativeAlert alertMessage
            )

        Msg.FormulaOneLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneLeaderboards =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneLeaderboards
                }

        Msg.FormulaOneEventsResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneEvents =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneEvents
                }

        Msg.FormulaELeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaELeaderboards =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaELeaderboards
                }

        Msg.FormulaEEventsResponse spec result ->
            Return.noEffect
                { model
                    | formulaEEvents =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaEEvents
                }

        Msg.FormulaEEventEntrantsResponse spec result ->
            Return.noEffect
                { model
                    | formulaEEventEntrants =
                        Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaEEventEntrants
                }

        Msg.FormulaEEventLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaEEventLeaderboards =
                        Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaEEventLeaderboards
                }

        Msg.UpdateFormulaEPrediction spec updateMessage ->
            let
                prediction : Types.FormulaE.Prediction
                prediction =
                    case Helpers.Http.toMaybe model.userStatus of
                        Nothing ->
                            Types.FormulaE.emptyPrediction

                        Just user ->
                            Model.getFormulaEEventPrediction model user spec.eventId

                newPrediction : Types.FormulaE.Prediction
                newPrediction =
                    updateFormulaEPrediction updateMessage prediction
            in
            Return.noEffect
                { model
                    | formulaEPredictionInputs =
                        Dict.insert spec.eventId newPrediction model.formulaEPredictionInputs
                }

        Msg.UpdateFormulaEResult spec updateMessage ->
            let
                result : Types.FormulaE.Result
                result =
                    Model.getFormulaEEventResult model spec.eventId

                newResult : Types.FormulaE.Result
                newResult =
                    updateFormulaEPrediction updateMessage result
            in
            Return.noEffect
                { model
                    | formulaEResultInputs =
                        Dict.insert spec.eventId newResult model.formulaEResultInputs
                }

        Msg.SubmitFormulaEPrediction spec prediction ->
            ( { model
                | formulaEEventLeaderboards =
                    Dict.insert spec.eventId Helpers.Http.Inflight model.formulaEEventLeaderboards
              }
            , Effect.SubmitFormulaEPrediction spec prediction
            )

        Msg.SubmitFormulaEResult spec result ->
            ( { model
                | formulaEEventLeaderboards =
                    Dict.insert spec.eventId Helpers.Http.Inflight model.formulaEEventLeaderboards
              }
            , Effect.SubmitFormulaEResult spec result
            )

        Msg.SubmitFormulaEPredictionResponse spec result ->
            let
                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Prediction submitted successfully!"

                        Err _ ->
                            "Failed to submit prediction."
            in
            ( { model
                | formulaEEventLeaderboards =
                    Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaEEventLeaderboards
              }
            , Effect.NativeAlert alertMessage
            )

        Msg.SubmitFormulaEResultResponse spec result ->
            let
                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Result submitted successfully!"

                        Err _ ->
                            "Failed to submit result."
            in
            ( { model
                | formulaEEventLeaderboards =
                    Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaEEventLeaderboards
              }
            , Effect.NativeAlert alertMessage
            )

        Msg.OverUnderCompetitionsResponse result ->
            Return.noEffect
                { model | overUnderCompetitions = Helpers.Http.fromResult result }

        Msg.SetOverUnderAnswer competitionId questionId probability ->
            let
                updateCompetitionAnswers : Maybe (Dict.Dict Types.OverUnder.QuestionId Int) -> Maybe (Dict.Dict Types.OverUnder.QuestionId Int)
                updateCompetitionAnswers mAnswers =
                    mAnswers
                        |> Maybe.withDefault Dict.empty
                        |> Dict.insert questionId probability
                        |> Just
            in
            Return.noEffect
                { model
                    | overUnderAnswerInputs =
                        Dict.update competitionId updateCompetitionAnswers model.overUnderAnswerInputs
                }

        Msg.SubmitOverUnderAnswers competitionId answers ->
            ( { model
                | overUnderAnswerSubmitStatus =
                    Dict.insert competitionId Helpers.Http.Inflight model.overUnderAnswerSubmitStatus
              }
            , Effect.SubmitOverUnderAnswers { competitionId = competitionId } answers
            )

        Msg.SubmitOverUnderAnswersResponse spec result ->
            let
                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Answers submitted successfully!"

                        Err _ ->
                            "Failed to submit answers."
            in
            -- The answers we fetched are now out of date, but the answers the user
            -- entered are kept, and getOverUnderAnswer prefers those, so the page
            -- carries on showing the right thing until the next fetch.
            ( { model
                | overUnderAnswerSubmitStatus =
                    Dict.insert spec.competitionId (Helpers.Http.fromResult result) model.overUnderAnswerSubmitStatus
              }
            , Effect.NativeAlert alertMessage
            )

        Msg.OverUnderLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | overUnderLeaderboards =
                        Dict.insert spec.competitionId (Helpers.Http.fromResult result) model.overUnderLeaderboards
                }

        Msg.FormulaOneEventSessionsResponse spec result ->
            let
                newModel : Model key
                newModel =
                    { model
                        | formulaOneSessions =
                            Dict.insert spec.eventId (Helpers.Http.fromResult result) model.formulaOneSessions
                    }

                mPrevSessionId : Maybe Types.FormulaOne.SessionId
                mPrevSessionId =
                    case model.route of
                        Route.FormulaOneSession _ eventId sessionId ->
                            if eventId /= spec.eventId then
                                Nothing

                            else
                                result
                                    |> Result.toMaybe
                                    |> Maybe.withDefault []
                                    |> Helpers.List.findPrevNext (\s -> s.id == sessionId)
                                    |> .prev
                                    |> Maybe.map .id

                        _ ->
                            Nothing
            in
            case mPrevSessionId of
                Nothing ->
                    Return.noEffect newModel

                Just prevSessionId ->
                    if Dict.member prevSessionId newModel.formulaOneSessionLeaderboards then
                        Return.noEffect newModel

                    else
                        getData (Types.Data.FormulaOneSessionLeaderboard { sessionId = prevSessionId }) newModel

        Msg.FormulaOneEntrantsResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneEntrants =
                        Dict.insert spec.sessionId (Helpers.Http.fromResult result) model.formulaOneEntrants
                }

        Msg.FormulaOneSessionLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneSessionLeaderboards =
                        Dict.insert spec.sessionId (Helpers.Http.fromResult result) model.formulaOneSessionLeaderboards
                }

        Msg.FormulaOneConcordantLeaderboardResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneConcordantLeaderboards =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneConcordantLeaderboards
                }

        Msg.FormulaOneConstructorStandingsResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneConstructorStandings =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneConstructorStandings
                }

        Msg.FormulaOneSeasonLeaderboardResponse spec result ->
            let
                restoredEntry : Dict Types.FormulaOne.Season (List Types.FormulaOne.TeamId)
                restoredEntry =
                    case result of
                        Err _ ->
                            model.formulaOneSeasonPredictionEntry

                        Ok leaderboard ->
                            case Helpers.Http.toMaybe model.userStatus of
                                Nothing ->
                                    model.formulaOneSeasonPredictionEntry

                                Just user ->
                                    case userPredictionFromSeasonLeaderboard user.id leaderboard of
                                        Nothing ->
                                            model.formulaOneSeasonPredictionEntry

                                        Just teamIds ->
                                            Dict.insert spec.season teamIds model.formulaOneSeasonPredictionEntry
            in
            Return.noEffect
                { model
                    | formulaOneSeasonLeaderboards =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneSeasonLeaderboards
                    , formulaOneSeasonPredictionEntry = restoredEntry
                }

        Msg.FormulaOneDriverStandingsResponse spec result ->
            Return.noEffect
                { model
                    | formulaOneDriverStandings =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneDriverStandings
                }

        Msg.FormulaOneSeasonTeamsResponse spec result ->
            let
                initialEntry : List Types.FormulaOne.FormulaOneTeam -> Dict Types.FormulaOne.Season (List Types.FormulaOne.TeamId)
                initialEntry teams =
                    case Dict.member spec.season model.formulaOneSeasonPredictionEntry of
                        True ->
                            model.formulaOneSeasonPredictionEntry

                        False ->
                            let
                                defaultOrder : List Types.FormulaOne.TeamId
                                defaultOrder =
                                    List.map Types.FormulaOne.teamId teams

                                teamIds : List Types.FormulaOne.TeamId
                                teamIds =
                                    case Helpers.Http.toMaybe model.userStatus of
                                        Nothing ->
                                            defaultOrder

                                        Just user ->
                                            model.formulaOneSeasonLeaderboards
                                                |> Dict.get spec.season
                                                |> Maybe.andThen Helpers.Http.toMaybe
                                                |> Maybe.andThen (userPredictionFromSeasonLeaderboard user.id)
                                                |> Maybe.withDefault defaultOrder
                            in
                            Dict.insert spec.season teamIds model.formulaOneSeasonPredictionEntry
            in
            Return.noEffect
                { model
                    | formulaOneSeasonTeams =
                        Dict.insert spec.season (Helpers.Http.fromResult result) model.formulaOneSeasonTeams
                    , formulaOneSeasonPredictionEntry =
                        case result of
                            Err _ ->
                                model.formulaOneSeasonPredictionEntry

                            Ok teams ->
                                initialEntry teams
                }

        Msg.ReorderFormulaOneSeasonPrediction season oldIndex newIndex ->
            let
                currentOrder : List Types.FormulaOne.TeamId
                currentOrder =
                    Dict.get season model.formulaOneSeasonPredictionEntry
                        |> Maybe.withDefault []

                newOrder : List Types.FormulaOne.TeamId
                newOrder =
                    Helpers.List.moveByIndex oldIndex newIndex currentOrder
            in
            Return.noEffect
                { model
                    | formulaOneSeasonPredictionEntry =
                        Dict.insert season newOrder model.formulaOneSeasonPredictionEntry
                }

        Msg.SubmitFormulaOneSeasonPrediction season teamIds ->
            ( model
            , Effect.SubmitFormulaOneSeasonPrediction { season = season } teamIds
            )

        Msg.FormulaOneSeasonPredictionResponse result ->
            let
                alertMessage : String
                alertMessage =
                    case result of
                        Ok _ ->
                            "Season prediction submitted successfully!"

                        Err _ ->
                            "Failed to submit season prediction."
            in
            ( model, Effect.NativeAlert alertMessage )


userPredictionFromSeasonLeaderboard : Types.User.Id -> Types.FormulaOne.SeasonLeaderboard -> Maybe (List Types.FormulaOne.TeamId)
userPredictionFromSeasonLeaderboard userId leaderboard =
    case List.filter (\row -> row.userId == userId) leaderboard.rows of
        [] ->
            Nothing

        row :: _ ->
            let
                teamIds : List Types.FormulaOne.TeamId
                teamIds =
                    row.rows
                        |> List.sortBy .predictedPosition
                        |> List.map .teamId
            in
            Helpers.List.emptyAsNothing teamIds


updateFormulaEPrediction : Msg.UpdateFormulaEPredictionMsg -> Types.FormulaE.Prediction -> Types.FormulaE.Prediction
updateFormulaEPrediction msg prediction =
    case msg of
        Msg.SetPole entrantId ->
            { prediction | pole = entrantId }

        Msg.SetFam entrantId ->
            { prediction | fam = entrantId }

        Msg.SetSam entrantId ->
            { prediction | sam = entrantId }

        Msg.SetFastestLap entrantId ->
            { prediction | fastestLap = entrantId }

        Msg.SetHgc entrantId ->
            { prediction | hgc = entrantId }

        Msg.SetFirst entrantId ->
            { prediction | first = entrantId }

        Msg.SetSecond entrantId ->
            { prediction | second = entrantId }

        Msg.SetThird entrantId ->
            { prediction | third = entrantId }

        Msg.SetFdnf entrantId ->
            { prediction | fdnf = entrantId }

        Msg.SetHst teamId ->
            { prediction | hst = teamId }

        Msg.SetSafetyCar safetyCar ->
            { prediction | safetyCar = Just safetyCar }
