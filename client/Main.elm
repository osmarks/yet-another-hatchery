import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes as HA
import Html.Events exposing (..)
import Url
import Url.Parser exposing (Parser, (</>), int, map, oneOf, s, string, top)
import Http
import Time
import Markdown

import API
import Ports

main : Program () Model Msg
main =
  Browser.application
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , onUrlChange = UrlChanged
    , onUrlRequest = LinkClicked
    }

type Route
    = MainPage
    | Manage
    | NotFound
    | About

routeParser : Parser (Route -> a) a
routeParser =
     oneOf
        [ map MainPage top
        , map Manage (s "manage")
        , map About (s "about")
        ]

parseRoute : Url.Url -> Route
parseRoute url = Maybe.withDefault NotFound (Url.Parser.parse routeParser url)

type alias HttpResult a = Result Http.Error a

type alias Model =
    { key : Nav.Key
    , route : Route
    , dragons : HttpResult (List API.Dragon)
    , lastCommandResult : LastCommandResult
    , newDragonCode : String
    , viewRate : Float
    , refreshRate : Float
    }

loadDragons : Cmd Msg
loadDragons = Http.send DragonsLoaded API.getDragons

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key (parseRoute url) (Ok []) None "" 10000 30000, loadDragons )

type LastCommandResult
    = SubmissionResult (HttpResult API.Dragon)
    | DeletionResult (HttpResult ())
    | None

type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | DragonsLoaded (HttpResult (List API.Dragon))
    | CodeChange String
    | Submit
    | Delete
    | SubmitResult (HttpResult API.Dragon)
    | DeleteResult (HttpResult ())
    | RefreshDragons
    | ViewDragons
    | UpdateViewRate String

viewRateLimits : { max : Float, min : Float }
viewRateLimits = { max = 240.0, min = 10.0 }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url -> ( model, Nav.pushUrl model.key (Url.toString url) )
                Browser.External href -> ( model, Nav.load href )
        UrlChanged url -> ( { model | route = parseRoute url }, Ports.viewDragon "PhZHf" )
        DragonsLoaded d -> ( { model | dragons = d }, Cmd.none )
        CodeChange c -> ( { model | newDragonCode = c }, Cmd.none )
        Submit -> ( model, Http.send SubmitResult (API.submitDragon model.newDragonCode) )
        Delete -> ( model, Http.send DeleteResult (API.deleteDragon model.newDragonCode) )
        SubmitResult r -> ( { model | lastCommandResult = SubmissionResult r }, Cmd.none )
        DeleteResult r -> ( { model | lastCommandResult = DeletionResult r }, Cmd.none )
        RefreshDragons -> ( model, loadDragons )
        ViewDragons ->
            case model.dragons of
                Ok ds -> ( model, Cmd.batch <| List.map (\d -> Ports.viewDragon d.code) ds )
                Err _ -> ( model, Cmd.none )
        UpdateViewRate vr ->
            case String.toFloat vr of
                Just v -> ( { model | viewRate = (Basics.max viewRateLimits.min v |> Basics.min viewRateLimits.max) * 1000 }, Cmd.none )
                Nothing -> ( model, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions m =
  Sub.batch
    [ Time.every m.refreshRate (always RefreshDragons)
    , Time.every m.viewRate (always ViewDragons)
    ]

view : Model -> Browser.Document Msg
view model =
    case model.route of
        MainPage -> 
            page "Main Page"
                [ div [ class "view-delay-control" ]
                    [ text "Delay between view cycles (seconds): "
                    , input [ 
                        attribute "type" "number"
                        , value <| String.fromFloat (model.viewRate / 1000)
                        , HA.min (String.fromFloat viewRateLimits.min)
                        , HA.max (String.fromFloat viewRateLimits.max)
                        , onInput UpdateViewRate ] []
                    ]
                , viewHttpResult (div [ class "dragon-pictures" ] << List.map viewDragonImage) model.dragons
                ]
        Manage -> 
            page "Manage Dragons"
                [ input [ attribute "type" "text", placeholder "Code", value model.newDragonCode, onInput CodeChange, class "code-input" ] []
                , button [ onClick Submit, class "submit-button" ] [ text "Submit" ]
                , button [ onClick Delete, class "delete-button" ] [ text "Delete" ]
                , viewChangeResult model.lastCommandResult
                ]
        About ->
            page "About"
                [ div [ class "about-container" ] [ div [ class "about" ] [ Markdown.toHtml [] aboutText ] ] ]
        NotFound ->
            page "Page Not Found"
                [ p [ class "center-text" ] [ text "This is not the webpage you are looking for. Try going back to the main page." ]
                ]     

aboutText : String
aboutText = """
This [DragonCave](https://dragcave.net/) hatchery (Yet Another Hatchery) was created partly as a fun project, and partly as I wanted to make a more effective hatchery using modern (basically, non-PHP) technologies.
For suggestions, bug reports, etc, create an issue at [the repository](https://github.com/osmarks/yet-another-hatchery), contact me on the unofficial DC Discord server, or PM me (osmarks) on the forums.
Eggs are viewed automatically and somewhat faster by sending out HTTP requests via JavaScript instead of via images, and will be automatically removed if sick.
Unfortunately, at this time, only adding eggs by code is possible, due to the fact that I don't have access to the API.

This hatchery is open-source! View the code [here](https://github.com/osmarks/yet-another-hatchery).
"""

viewChangeResult : LastCommandResult -> Html msg
viewChangeResult r =
    case r of
        SubmissionResult re -> viewHttpResult viewDragonInfo re
        DeletionResult re -> viewHttpResult (\_ -> textDiv "Deletion successful.") re
        None -> div [] []

viewDragonImage : API.Dragon -> Html msg
viewDragonImage d =
    a [ href ("https://dragcave.net/view/" ++ d.code) ] [ img [ src ("https://dragcave.net/image/" ++ d.code) ] []]

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

viewDragonType : API.DragonType -> String
viewDragonType t =
    case t of
        API.Hatchling -> "Hatchling"
        API.Egg -> "Egg"

viewDragonInfo : API.Dragon -> Html msg
viewDragonInfo d = div [ class "dragon-info" ]
    [ field "Sick" (viewBool d.sick)
    , field "Views" (String.fromInt d.views)
    , field "Unique Views" (String.fromInt d.uniqueViews)
    , field "Clicks" (String.fromInt d.clicks)
    , field "Code" d.code
    , field "Dragon Type" (viewDragonType d.dragonType)
    , field "Hours of Life Remaining" (String.fromInt d.hours)
    ]

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

page : String -> List (Html msg) -> Browser.Document msg
page title contents =
    { title = title
    , body =
        [ navbar
        , h1 [ class "center-text" ] [ text title ]
        , div [ class "contents" ] contents
        ]
    }

navbar : Html msg
navbar =
    nav []
    [ ul []
        [ navLink "Home" "/"
        , navLink "Manage Dragons" "/manage"
        , navLink "About" "/about"
        ]
    ]

navLink : String -> String -> Html msg
navLink txt url = li [] [ a [ href url ] [ text txt ] ]