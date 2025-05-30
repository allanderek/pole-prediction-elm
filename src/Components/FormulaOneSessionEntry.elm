module Components.FormulaOneSessionEntry exposing
    ( Kind(..)
    , view
    , viewEntrant
    )

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Extra
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Types.FormulaOne
import Types.User exposing (User)


type Kind
    = Prediction
    | Result


type alias Config msg =
    { kind : Kind
    , user : User
    , entrants : List Types.FormulaOne.Entrant
    , reorderMessage : Int -> Int -> msg
    , submitMessage : msg
    }


view : Config msg -> Html msg
view config =
    let
        decodeReorderEvent : Decoder msg
        decodeReorderEvent =
            Decode.succeed config.reorderMessage
                |> Pipeline.required "oldIndex" Decode.int
                |> Pipeline.required "newIndex" Decode.int
                |> Decode.field "detail"

        submitText : String
        submitText =
            case config.kind of
                Prediction ->
                    "Submit Predictions"

                Result ->
                    "Submit Results"
    in
    Html.div
        []
        [ Html.node
            "sortable-list"
            [ Html.Events.on "item-reordered" decodeReorderEvent ]
            (List.map (viewEntrant { showPosition = True, withHandle = True }) config.entrants)
        , Html.button
            [ Html.Events.onClick config.submitMessage ]
            [ Html.text submitText ]
        ]


viewEntrant : { showPosition : Bool, withHandle : Bool } -> Types.FormulaOne.Entrant -> Html msg
viewEntrant config entrant =
    let
        teamColor : String
        teamColor =
            case entrant.teamPrimaryColor == "#FFFFFF" of
                False ->
                    entrant.teamPrimaryColor

                True ->
                    entrant.teamSecondaryColor
    in
    Html.div
        [ Html.Attributes.attribute "data-id" (String.fromInt entrant.id)
        , Html.Attributes.class "entrant"
        ]
        [ case config.showPosition of
            False ->
                Html.Extra.nothing

            True ->
                -- A placeholder which is then filled in by CSS with the position.
                Html.span [ Html.Attributes.class "entrant-position" ] []
        , Html.span
            [ Html.Attributes.class "entrant-driver" ]
            [ Html.text entrant.driver ]
        , Html.span
            [ Html.Attributes.class "entrant-number" ]
            [ Html.text (String.fromInt entrant.number) ]
        , Html.span
            [ Html.Attributes.class "entrant-team"
            , Html.Attributes.style "color" teamColor
            ]
            [ Html.text entrant.teamShortName ]
        , case config.withHandle of
            True ->
                Html.span
                    [ Html.Attributes.class "sortable-handle" ]
                    [ Html.text "↕" ]

            False ->
                Html.Extra.nothing
        ]
