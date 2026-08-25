module Helpers.Http exposing
    ( Status(..)
    , fromResult
    , isInflight
    , map
    , toMaybe
    )

import Http


type Status a
    = Ready
    | Inflight
    | Failed Http.Error
    | Succeeded a


fromResult : Result Http.Error a -> Status a
fromResult result =
    case result of
        Err error ->
            Failed error

        Ok a ->
            Succeeded a


isInflight : Status a -> Bool
isInflight status =
    case status of
        Inflight ->
            True

        _ ->
            False


map : (a -> b) -> Status a -> Status b
map f status =
    case status of
        Ready ->
            Ready

        Inflight ->
            Inflight

        Failed error ->
            Failed error

        Succeeded a ->
            Succeeded (f a)


toMaybe : Status a -> Maybe a
toMaybe status =
    case status of
        Ready ->
            Nothing

        Inflight ->
            Nothing

        Failed _ ->
            Nothing

        Succeeded a ->
            Just a
