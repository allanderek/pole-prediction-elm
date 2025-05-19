module Components.FormulaOneSessionEntry exposing
    ( Kind(..)
    , view
    )

import Helpers.Decode
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
    , toMessage : Types.FormulaOne.EntrantId -> Int -> Int -> msg
    }


view : Config msg -> Html msg
view config =
    let
        viewEntrant : Types.FormulaOne.Entrant -> Html msg
        viewEntrant entrant =
            Html.div
                [ Html.Attributes.attribute "data-id" (String.fromInt entrant.id) ]
                [ Html.text entrant.driver ]

        decodeReorderEvent : Decoder msg
        decodeReorderEvent =
            Decode.succeed config.toMessage
                |> Pipeline.required "itemId" Helpers.Decode.stringAsInt
                |> Pipeline.required "oldIndex" Decode.int
                |> Pipeline.required "newIndex" Decode.int
                |> Decode.field "detail"
    in
    Html.node
        "sortable-list"
        [ Html.Events.on "item-reordered" decodeReorderEvent ]
        (List.map viewEntrant config.entrants)
