module Helpers.Http exposing
    ( Status(..)
    , combineStatuses
    , errorToString
    , fromResult
    , isInflight
    , isUnauthorized
    , map
    , toErrorMaybe
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


toErrorMaybe : Status a -> Maybe Http.Error
toErrorMaybe status =
    case status of
        Failed error ->
            Just error

        Ready ->
            Nothing

        Inflight ->
            Nothing

        Succeeded _ ->
            Nothing


combineStatuses : (a -> b -> c) -> Status a -> Status b -> Status c
combineStatuses f statusA statusB =
    case ( statusA, statusB ) of
        ( Ready, _ ) ->
            Ready

        ( _, Ready ) ->
            Ready

        ( Failed error, _ ) ->
            Failed error

        ( _, Failed error ) ->
            Failed error

        ( Inflight, _ ) ->
            Inflight

        ( _, Inflight ) ->
            Inflight

        ( Succeeded a, Succeeded b ) ->
            Succeeded (f a b)


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadUrl _ ->
            "Misconfigured request sent."

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus _ ->
            "The request was not successful."

        Http.BadBody _ ->
            "The request succeeded but we didn't understand the response. Please refresh the page."


isUnauthorized : Http.Error -> Bool
isUnauthorized error =
    case error of
        Http.BadStatus status ->
            status == 401

        _ ->
            False
