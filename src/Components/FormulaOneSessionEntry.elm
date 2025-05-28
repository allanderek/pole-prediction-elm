module Components.FormulaOneSessionEntry exposing
    ( Kind(..)
    , view
    )

import Html exposing (Html)
import Html.Attributes
import Html.Events
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
        viewEntrant : Types.FormulaOne.Entrant -> Html msg
        viewEntrant entrant =
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
                [ Html.span
                    [ Html.Attributes.class "entrant-position" ]
                    []
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
                ]

        decodeReorderEvent : Decoder msg
        decodeReorderEvent =
            Decode.succeed config.reorderMessage
                |> Pipeline.required "oldIndex" Decode.int
                |> Pipeline.required "newIndex" Decode.int
                |> Decode.field "detail"
    in
    Html.div
        []
        [ Html.node
            "sortable-list"
            [ Html.Events.on "item-reordered" decodeReorderEvent ]
            (List.map viewEntrant config.entrants)
        , Html.button
            [ Html.Events.onClick config.submitMessage ]
            [ Html.text "Submit" ]
        ]
