module Pages.Profile exposing (view)

import Components.Login
import Helpers.Events
import Helpers.Http
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events
import Maybe.Extra
import Model exposing (Model)
import Msg exposing (Msg)
import Types.Profile
import Types.User exposing (User)


view : Model key -> List (Html Msg)
view model =
    let
        viewFullnameForm : User -> Html Msg
        viewFullnameForm user =
            let
                disabled : Bool
                disabled =
                    Helpers.Http.isInflight model.profileStatus

                form : Types.Profile.Form
                form =
                    case model.profileForm of
                        Just f ->
                            f

                        Nothing ->
                            Types.Profile.initForm user
            in
            Html.form
                [ Html.Events.onSubmit (Msg.SubmitEditedProfile form)
                , Attributes.disabled disabled
                ]
                [ Html.label
                    [ Attributes.class "form-label" ]
                    [ Html.text "Full Name"
                    , Html.input
                        [ Attributes.type_ "text"
                        , Attributes.value form.fullname
                        , Attributes.name "fullname"
                        , Helpers.Events.onInputOrDisabled disabled Msg.EditProfileFullNameInput
                        , Attributes.placeholder "Full Name"
                        , Attributes.disabled disabled
                        ]
                        []
                    ]
                , Html.button
                    [ Attributes.type_ "button"
                    , Helpers.Events.onClickOrDisabled disabled Msg.CancelEditProfile
                    ]
                    [ Html.text "Cancel" ]
                , Html.button
                    [ Attributes.type_ "submit"
                    , Attributes.name "submit"
                    , Attributes.value "submit"
                    , Attributes.disabled disabled
                    ]
                    [ Html.text "Submit" ]
                ]
    in
    [ Html.h1
        []
        [ Html.text "Profile Page" ]
    , case Helpers.Http.toMaybe model.userStatus of
        Just user ->
            Html.dl
                []
                [ Html.dt
                    []
                    [ Html.text "Username" ]
                , Html.dd
                    []
                    [ Html.text user.username ]
                , Html.dt
                    []
                    [ Html.text "Name" ]
                , Html.dd
                    []
                    (case model.editingProfile of
                        False ->
                            [ Html.text user.fullname
                            , Html.button
                                [ Attributes.class "edit-profile-button"
                                , Html.Events.onClick Msg.EditProfile
                                ]
                                [ Html.text "Edit" ]
                            ]

                        True ->
                            [ viewFullnameForm user ]
                    )
                , Html.dt
                    []
                    [ Html.text "Logout" ]
                , Html.dd
                    []
                    [ Html.button
                        [ Attributes.class "logout-button"
                        , Html.Events.onClick Msg.Logout
                        ]
                        [ Html.text "Logout" ]
                    ]
                ]

        Nothing ->
            Components.Login.view model
    ]
