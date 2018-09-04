import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Url
import Url.Parser exposing (Parser, (</>), int, map, oneOf, s, string, top)

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
    | Submit
    | NotFound

routeParser : Parser (Route -> a) a
routeParser =
     oneOf
        [ map MainPage top
        , map Submit (s "submit")
        ]

parseRoute : Url.Url -> Route
parseRoute url = Maybe.withDefault NotFound (Url.Parser.parse routeParser url)

type alias Model =
    { key : Nav.Key
    , route : Route
    }

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key <| parseRoute url, Cmd.none )

type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url -> ( model, Nav.pushUrl model.key (Url.toString url) )
                Browser.External href -> ( model, Nav.load href )
        UrlChanged url -> ( { model | route = parseRoute url }, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

view : Model -> Browser.Document Msg
view model =
    case model.route of
        MainPage -> 
            page "Main Page"
                [ text "Placeholder"
                ]
        Submit -> 
            page "Submit a Dragon"
                [ text "Placeholder"
                ]
        NotFound ->
            page "Page Not Found"
                [ p [ class "center-text" ] [ text "This is not the webpage you are looking for. Try going back to the main page." ]
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
        [ navLink "Home" "/"
        , navLink "Submit a Dragon" "/submit"
        ]
    ]

navLink : String -> String -> Html msg
navLink txt url = li [] [ a [ href url ] [ text txt ] ]