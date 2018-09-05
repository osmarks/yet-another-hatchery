module Util exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http

type alias HttpResult a = Result Http.Error a

viewHttpError : Http.Error -> Html msg
viewHttpError e =
    case e of
        Http.BadUrl u -> text <| "Invalid URL in request: " ++ u
        Http.Timeout -> text "Request timed out"
        Http.NetworkError -> text "Network error"
        Http.BadStatus r -> div [] -- use http.cat for errors!
            [ textDiv <| (String.fromInt r.status.code) ++ " " ++ r.status.message ++ "."
            , textDiv r.body
            , img [ class "http-cat-error", src ("https://http.cat/" ++ String.fromInt r.status.code) ] []
            ]
        Http.BadPayload emsg _ -> text emsg

viewHttpResult : (a -> Html msg) -> Result Http.Error a -> Html msg
viewHttpResult v res =
    case res of
        Ok x -> v x
        Err e -> 
            div [ class "error" ] [ viewHttpError e ]

textDiv : String -> Html msg
textDiv s = div [] [ text s ]

field : String -> String -> Html msg
field name contents =
    textDiv (name ++ ": " ++ contents)

viewBool : Bool -> String
viewBool b =
    case b of
        True -> "yes"
        False -> "no"