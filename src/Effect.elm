module Effect exposing (Effect(..))


type Effect
    = None
    | PushUrl String
    | LoadUrl String
