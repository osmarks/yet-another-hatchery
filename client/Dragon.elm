module Dragon exposing (..)

import Json.Decode as D
import Json.Encode as E
import Html exposing (..)
import Html.Attributes exposing (..)

import Util

type DragonType = Hatchling | Egg

type alias Dragon =
    { sick : Bool
    , views : Int
    , uniqueViews : Int
    , clicks : Int
    , code : String
    , dragonType : DragonType
    , hours : Int
    }

decodeDragonType : D.Decoder DragonType
decodeDragonType =
    D.string
    |> D.andThen (\s -> case s of
        "hatchling" -> D.succeed Hatchling
        "egg" -> D.succeed Egg
        _ -> D.fail "invalid dragon type"
    )

decode : D.Decoder Dragon
decode =
    D.map7 Dragon
        (D.field "sick" D.bool)
        (D.field "views" D.int)
        (D.field "uniqueViews" D.int)
        (D.field "clicks" D.int)
        (D.field "code" D.string)
        (D.field "type" decodeDragonType)
        (D.field "hoursRemaining" D.int)

viewDragonType : DragonType -> String
viewDragonType t =
    case t of
        Hatchling -> "Hatchling"
        Egg -> "Egg"

viewInfo : Dragon -> Html msg
viewInfo d = div [ class "dragon-info" ]
    [ Util.field "Code" d.code
    , Util.field "Sick" (Util.viewBool d.sick)
    , Util.field "Views" (String.fromInt d.views)
    , Util.field "Unique Views" (String.fromInt d.uniqueViews)
    , Util.field "Clicks" (String.fromInt d.clicks)
    , Util.field "Dragon Type" (viewDragonType d.dragonType)
    , Util.field "Hours of Life Remaining" (String.fromInt d.hours)
    ]

viewImage : Dragon -> Html msg
viewImage d =
    a [ href ("https://dragcave.net/view/" ++ d.code), title d.code, target "_blank" ] [ img [ src ("https://dragcave.net/image/" ++ d.code), alt d.code ] []]