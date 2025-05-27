module Components.SeasonNav exposing (view)

import Helpers.Classes
import Html exposing (Html)
import Html.Attributes as Attributes
import Route exposing (Route)


type alias Config a =
    { currentSeason : a
    , viewedSeason : a
    , allSeasons : List a
    , toRoute : a -> Route
    , toName : a -> String
    }


view : Config season -> Html msg
view config =
    let
        viewLink : season -> Html msg
        viewLink linkSeason =
            let
                seasonArg : Maybe season
                seasonArg =
                    case linkSeason == config.currentSeason of
                        True ->
                            Nothing

                        False ->
                            Just linkSeason
            in
            Html.li
                []
                [ Html.a
                    [ Attributes.class "season-link"
                    , config.toRoute linkSeason
                        |> Route.href
                    , Helpers.Classes.active (linkSeason == config.viewedSeason)
                    ]
                    [ config.toName linkSeason |> Html.text ]
                ]
    in
    Html.details
        [ Attributes.class "season-nav" ]
        [ Html.summary [] [ Html.text "Seasons" ]
        , Html.nav
            []
            [ Html.ul
                []
                (List.map viewLink config.allSeasons)
            ]
        ]
