module Helpers.Time exposing (isEarlier)

import Time


isEarlier : Time.Posix -> Time.Posix -> Bool
isEarlier a b =
    Time.posixToMillis a < Time.posixToMillis b
