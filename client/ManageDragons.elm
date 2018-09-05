module ManageDragons exposing (..)

import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import API
import Util
import Dragon exposing (Dragon)

type Msg
    = Submit
    | Delete
    | CommandResult CommandResult
    | CodesChanged String

type CommandResult
    = SubmissionResult (Util.HttpResult (List Dragon))
    | DeletionResult (Util.HttpResult ())
    | None

type alias Model =
    { codes : List String
    , result : CommandResult
    }

viewChangeResult : CommandResult -> Html msg
viewChangeResult r =
    case r of
        SubmissionResult re -> Util.viewHttpResult (div [] << List.intersperse (hr [] []) << List.map Dragon.viewInfo) re
        DeletionResult re -> Util.viewHttpResult (\_ -> Util.textDiv "Deletion successful.") re
        None -> div [] []

view : Model -> Html Msg
view model = div []
    [ input [ attribute "type" "text", placeholder "Codes (space-separated)", value (String.join " " model.codes), onInput CodesChanged, class "code-input" ] []
    , button [ onClick Submit, class "submit-button" ] [ text "Submit" ]
    , button [ onClick Delete, class "delete-button" ] [ text "Delete" ]
    , viewChangeResult model.result
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Submit -> ( model, Http.send (SubmissionResult >> CommandResult) <| API.submitDragons model.codes )
        Delete -> ( model, Http.send (DeletionResult >> CommandResult) <| API.deleteDragons model.codes )
        CommandResult r -> ( { model | result = r }, Cmd.none )
        CodesChanged c -> ( { model | codes = String.split " " c }, Cmd.none )

init : Model
init = Model [] None