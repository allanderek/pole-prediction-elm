module Helpers.List exposing
    ( emptyAsNothing
    , filterByFirst
    , findWith
    , firstJust
    , moveByIndex
    )

import List.Extra


filterByFirst : List ( Bool, a ) -> List a
filterByFirst items =
    items
        |> List.filter Tuple.first
        |> List.map Tuple.second


firstJust : List (Maybe a) -> Maybe a
firstJust items =
    case items of
        (Just item) :: _ ->
            Just item

        Nothing :: rest ->
            firstJust rest

        [] ->
            Nothing


emptyAsNothing : List a -> Maybe (List a)
emptyAsNothing items =
    case List.isEmpty items of
        True ->
            Nothing

        False ->
            Just items


findWith : a -> (b -> a) -> List b -> Maybe b
findWith itemToFind getter items =
    List.Extra.find
        (\item -> getter item == itemToFind)
        items


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
