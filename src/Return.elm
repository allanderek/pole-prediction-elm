module Return exposing
    ( addEffect
    , noEffect
    )

import Effect exposing (Effect)


noEffect : model -> ( model, Effect )
noEffect model =
    ( model, Effect.None )


addEffect : Effect -> ( model, Effect ) -> ( model, Effect )
addEffect effect ( model, existingEffect ) =
    ( model, Effect.Batch [ existingEffect, effect ] )
