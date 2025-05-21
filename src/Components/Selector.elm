module Components.Selector exposing
    ( Config
    , Group
    , Option
    , flatNoGroups
    , hasNoOptions
    , nameAsValue
    , pleaseSelectValue
    , view
    )

import Helpers.Attributes
import Helpers.Events
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events


type alias Config msg =
    { classPrefix : String
    , groups : List Group
    , onInput : String -> msg
    , onBlur : Maybe msg
    , current : String
    , disabled : Bool
    , pleaseSelect : Maybe String
    }


flatNoGroups : List Option -> List Group
flatNoGroups options =
    [ { name = ""
      , options = options
      }
    ]


type alias Group =
    { name : String
    , options : List Option
    }


type alias Option =
    { name : String
    , value : String
    }


nameAsValue : String -> Option
nameAsValue name =
    { name = name
    , value = name
    }


pleaseSelectValue : String
pleaseSelectValue =
    ""


hasNoOptions : List Group -> Bool
hasNoOptions groups =
    let
        isEmptyGroup : Group -> Bool
        isEmptyGroup group =
            List.isEmpty group.options
    in
    List.all isEmptyGroup groups


view : Config msg -> Html msg
view config =
    -- Some thoughts on why we don't use Attributes.value and why we set the value on the select
    -- rather than use 'Attributes.selected' on the option.
    -- https://discourse.elm-lang.org/t/how-can-i-reset-a-select-control/6005/4?u=allanderek
    -- I found that it didn't work as expected so I'm doing both.
    let
        makeChoiceOption : Option -> Html msg
        makeChoiceOption option =
            Html.option
                [ Attributes.value option.value
                , Attributes.selected (option.value == config.current)
                ]
                [ Html.text option.name ]

        viewGroup : Group -> List (Html msg)
        viewGroup group =
            case String.isEmpty group.name of
                True ->
                    List.map makeChoiceOption group.options

                False ->
                    [ Html.optgroup
                        [ Helpers.Attributes.label group.name ]
                        (List.map makeChoiceOption group.options)
                    ]
    in
    case hasNoOptions config.groups of
        True ->
            Html.input
                [ config.onInput |> Events.onInput
                , Attributes.value config.current
                ]
                []

        False ->
            let
                groups : List Group
                groups =
                    case config.pleaseSelect of
                        Just pleaseSelect ->
                            { name = pleaseSelectValue
                            , options =
                                [ { value = ""
                                  , name = pleaseSelect
                                  }
                                ]
                            }
                                :: config.groups

                        Nothing ->
                            config.groups
            in
            Html.select
                [ Attributes.class (config.classPrefix ++ "-select")

                -- See the above linked discourse thread, but I found that setting this just introduced a bunch
                -- of unexpected behaviour, most notably the 'Please select' text for the 'empty option' would
                -- disappear after a 'while'. Anyway removing this seemed to fix all issues. Though I understand
                -- we would potentially have issue with disabled inputs.
                -- , Encode.string config.current
                --     |> Attributes.property "value"
                , Helpers.Events.onInputOrDisabled config.disabled config.onInput
                , case config.onBlur of
                    Just onBlur ->
                        onBlur |> Events.onBlur

                    Nothing ->
                        Attributes.class "non-blurrable"
                ]
                (List.map viewGroup groups
                    |> List.concat
                )
