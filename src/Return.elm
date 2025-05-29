module Return exposing
    ( addEffect
    , combine
    , noEffect
    )

import Effect exposing (Effect)


noEffect : model -> ( model, Effect )
noEffect model =
    ( model, Effect.None )


addEffect : Effect -> ( model, Effect ) -> ( model, Effect )
addEffect effect ( model, existingEffect ) =
    ( model, Effect.Batch [ existingEffect, effect ] )


combine : (model -> ( model, Effect )) -> ( model, Effect ) -> ( model, Effect )
combine andThen ( model, effect ) =
    let
        ( newModel, newEffect ) =
            andThen model
    in
    ( newModel, Effect.Batch [ effect, newEffect ] )
