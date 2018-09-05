module API exposing (getDragons, submitDragons, deleteDragons)

import Json.Decode as D
import Json.Encode as E
import Url.Builder as Url
import Http

import Dragon exposing (Dragon)

apiRoot : String
apiRoot = "api"

getDragons : Http.Request (List Dragon)
getDragons = Http.get (Url.absolute [apiRoot, "hatchery"] []) (D.list Dragon.decode)

submitDragons : List String -> Http.Request (List Dragon)
submitDragons codes = Http.post (Url.absolute [apiRoot, "hatchery"] []) (Http.jsonBody <| E.list E.string codes) (D.list Dragon.decode)

deleteDragons : List String -> Http.Request ()
deleteDragons codes = Http.request
    { method = "DELETE"
    , headers = []
    , url = Url.absolute [apiRoot, "hatchery"] []
    , body = Http.jsonBody <| E.list E.string codes
    , expect = Http.expectStringResponse (\_ -> Ok ())
    , timeout = Nothing
    , withCredentials = False
    }