module Return exposing (noEffect)

import Effect exposing (Effect)


noEffect : model -> ( model, Effect )
noEffect model =
    ( model, Effect.None )
