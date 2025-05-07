module Components.UserName exposing
    ( formulaE
    , formulaOne
    )

import Html exposing (Html)
import Types.FormulaE
import Types.FormulaOne
import Types.User


formulaOne : Types.User.Id -> String -> Html msg
formulaOne userId name =
    championify userId Types.FormulaOne.currentChampion name


formulaE : Types.User.Id -> String -> Html msg
formulaE userId name =
    championify userId Types.FormulaE.currentChampion name


championify : Types.User.Id -> Types.User.Id -> String -> Html msg
championify candidate champion name =
    let
        augmentedName : String
        augmentedName =
            case candidate == champion of
                True ->
                    String.append name "🏆"

                False ->
                    name
    in
    Html.text augmentedName
