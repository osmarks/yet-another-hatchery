module API exposing (Dragon, DragonType(..), getDragons, submitDragon, deleteDragon)

import Json.Decode as D
import Json.Encode as E
import Url.Builder as Url
import Http

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

decodeDragon : D.Decoder Dragon
decodeDragon =
    D.map7 Dragon
        (D.field "sick" D.bool)
        (D.field "views" D.int)
        (D.field "uniqueViews" D.int)
        (D.field "clicks" D.int)
        (D.field "code" D.string)
        (D.field "type" decodeDragonType)
        (D.field "hoursRemaining" D.int)

apiRoot : String
apiRoot = "api"

getDragons : Http.Request (List Dragon)
getDragons = Http.get (Url.absolute [apiRoot, "hatchery"] []) (D.list decodeDragon)

submitDragon : String -> Http.Request Dragon
submitDragon code = Http.post (Url.absolute [apiRoot, "hatchery", code] []) (Http.emptyBody) decodeDragon

deleteDragon : String -> Http.Request ()
deleteDragon code = Http.request
    { method = "PUT"
    , headers = []
    , url = Url.absolute [apiRoot, "hatchery", code] []
    , body = Http.emptyBody
    , expect = Http.expectStringResponse (\_ -> Ok ())
    , timeout = Nothing
    , withCredentials = False
    }