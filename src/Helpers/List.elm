module Helpers.List exposing (moveByIndex)

import List.Extra


insertAt : Int -> a -> List a -> List a
insertAt index item items =
    -- Will always insert, if the index is out of bounds it inserts at the end
    List.concat
        [ List.take index items
        , [ item ]
        , List.drop index items
        ]


moveByIndex : Int -> Int -> List a -> List a
moveByIndex oldIndex newIndex items =
    case List.Extra.getAt oldIndex items of
        Nothing ->
            items

        Just itemToMove ->
            let
                withoutMovedItem : List a
                withoutMovedItem =
                    List.Extra.removeAt oldIndex items
            in
            insertAt newIndex itemToMove withoutMovedItem
