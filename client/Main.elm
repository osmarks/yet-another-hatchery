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
import ManageDragons
import Util
import Dragon exposing (Dragon)

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

type alias Model =
    { key : Nav.Key
    , route : Route
    , dragons : Util.HttpResult (List Dragon)
    , viewRate : Float
    , refreshRate : Float
    , manageDragons : ManageDragons.Model
    }

loadDragons : Cmd Msg
loadDragons = Http.send DragonsLoaded API.getDragons

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key (parseRoute url) (Ok []) 10000 30000 ManageDragons.init, loadDragons )

type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | DragonsLoaded (Util.HttpResult (List Dragon))
    | RefreshDragons
    | ViewDragons
    | UpdateViewRate String
    | ManageDragons ManageDragons.Msg

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
        RefreshDragons -> ( model, loadDragons )
        ViewDragons ->
            case model.dragons of
                Ok ds -> ( model, Cmd.batch <| List.map (\d -> Ports.viewDragon d.code) ds )
                Err _ -> ( model, Cmd.none )
        UpdateViewRate vr ->
            case String.toFloat vr of
                Just v -> ( { model | viewRate = (Basics.max viewRateLimits.min v |> Basics.min viewRateLimits.max) * 1000 }, Cmd.none )
                Nothing -> ( model, Cmd.none )
        ManageDragons m ->
            let ( mdl, cmd ) = ManageDragons.update m model.manageDragons
            in ( { model | manageDragons = mdl }, Cmd.map ManageDragons cmd )

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
                , Util.viewHttpResult viewDragons model.dragons
                ]
        Manage -> 
            page "Manage Dragons" [ ManageDragons.view model.manageDragons |> Html.map ManageDragons ]
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

Here is our mascot, Closed Timelike Curve the Chrono Xenowyrm:

[![Closed Timelike Curve](https://dragcave.net/image/4UtuJ)](https://dragcave.net/view/n/Closed%20Timelike%20Curve)
"""

viewDragons : List Dragon -> Html msg
viewDragons ds =
    div []
        [ div [ class "dragon-count" ] [ text <| String.fromInt <| List.length ds, text " dragons are currently in the hatchery, not sick and within safe view limits." ]
        , div [ class "dragon-pictures" ] <| List.map Dragon.viewImage ds
        ]

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
        [ a [ href "/" ] [ img [ src "/logo.png", class "logo" ] [] ]
        , navLink "Home" "/"
        , navLink "Manage Dragons" "/manage"
        , navLink "About" "/about"
        ]
    ]

navLink : String -> String -> Html msg
navLink txt url = li [] [ a [ href url ] [ text txt ] ]