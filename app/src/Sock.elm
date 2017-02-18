module Sock exposing ( listen
                     , update
                     , init
                     , add
                     , move
                     , stage
                     , reveal
                     , group
                     , vote
                     , delete
                     , menu
                     , createRetro
                     , MsgData(..)
                     , send
                     , Sender)

{-| This module provides a domain wrapper on top of the websocket format for the
purposes of retro.
-}

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Dict
import Sock.LowLevel

type MsgData = Error ErrorData
             | Stage StageData
             | Column ColumnData
             | Card CardData
             | Content ContentData
             | Move MoveData
             | Reveal RevealData
             | Group GroupData
             | Vote VoteData
             | Delete VoteData
             | User UserData
             | Retro RetroData

type alias ErrorData = { error : String }

errorDecoder : Decode.Decoder ErrorData
errorDecoder =
    Pipeline.decode ErrorData
        |> Pipeline.required "error" Decode.string

type alias StageData = { stage : String }

stageDecoder : Decode.Decoder StageData
stageDecoder =
    Pipeline.decode StageData
        |> Pipeline.required "stage" Decode.string

type alias ColumnData = { columnId : String, columnName : String, columnOrder : Int }

columnDecoder : Decode.Decoder ColumnData
columnDecoder =
    Pipeline.decode ColumnData
        |> Pipeline.required "columnId" Decode.string
        |> Pipeline.required "columnName" Decode.string
        |> Pipeline.required "columnOrder" Decode.int

type alias CardData = { columnId : String, cardId : String, revealed : Bool, votes : Int }

cardDecoder : Decode.Decoder CardData
cardDecoder =
    Pipeline.decode CardData
        |> Pipeline.required "columnId" Decode.string
        |> Pipeline.required "cardId" Decode.string
        |> Pipeline.required "revealed" Decode.bool
        |> Pipeline.required "votes" Decode.int

type alias ContentData = { columnId : String, cardId : String, cardText : String }

contentDecoder : Decode.Decoder ContentData
contentDecoder =
    Pipeline.decode ContentData
        |> Pipeline.required "columnId" Decode.string
        |> Pipeline.required "cardId" Decode.string
        |> Pipeline.required "cardText" Decode.string

type alias MoveData = { columnFrom : String, columnTo : String, cardId : String }

moveDecoder : Decode.Decoder MoveData
moveDecoder =
    Pipeline.decode MoveData
        |> Pipeline.required "columnFrom" Decode.string
        |> Pipeline.required "columnTo" Decode.string
        |> Pipeline.required "cardId" Decode.string

type alias RevealData = { columnId : String, cardId : String }

revealDecoder : Decode.Decoder RevealData
revealDecoder =
    Pipeline.decode RevealData
        |> Pipeline.required "columnId" Decode.string
        |> Pipeline.required "cardId" Decode.string

type alias GroupData = { columnFrom : String, cardFrom : String, columnTo : String, cardTo : String }

groupDecoder : Decode.Decoder GroupData
groupDecoder =
    Pipeline.decode GroupData
        |> Pipeline.required "columnFrom" Decode.string
        |> Pipeline.required "cardFrom" Decode.string
        |> Pipeline.required "columnTo" Decode.string
        |> Pipeline.required "cardTo" Decode.string

type alias VoteData = { columnId : String, cardId : String }

voteDecoder : Decode.Decoder VoteData
voteDecoder =
    Pipeline.decode VoteData
        |> Pipeline.required "columnId" Decode.string
        |> Pipeline.required "cardId" Decode.string

type alias UserData = { username : String }

userDecoder : Decode.Decoder UserData
userDecoder =
    Pipeline.decode UserData
        |> Pipeline.required "username" Decode.string

type alias RetroData = { id : String }

retroDecoder : Decode.Decoder RetroData
retroDecoder =
    Pipeline.decode RetroData
        |> Pipeline.required "id" Decode.string


listen : String -> (String -> msg) -> Sub msg
listen = Sock.LowLevel.listen

update : String -> model -> ((String, MsgData) -> model -> (model, Cmd msg)) -> (model, Cmd msg)
update data model f =
    let
        runOp decoder tagger d id m =
            case Decode.decodeString decoder d of
                Ok thing -> f (id, tagger thing) m
                Err e -> f (id, Error (ErrorData e)) m

        mux = Dict.fromList
              [ ("stage", runOp stageDecoder Stage)
              , ("card", runOp cardDecoder Card)
              , ("content", runOp contentDecoder Content)
              , ("column", runOp columnDecoder Column)
              , ("move", runOp moveDecoder Move)
              , ("reveal", runOp revealDecoder Reveal)
              , ("group", runOp groupDecoder Group)
              , ("vote", runOp voteDecoder Vote)
              , ("error", runOp errorDecoder Error)
              , ("delete", runOp voteDecoder Delete)
              , ("user", runOp userDecoder User)
              , ("retro", runOp retroDecoder Retro)
              ]

        runMux { id, op, data } model =
            case Dict.get op mux of
                Just guy ->
                    guy data id model

                Nothing ->
                    (model, Cmd.none)
    in
        Sock.LowLevel.update data model runMux

type alias Sender msg = String -> Encode.Value -> Cmd msg

send : String -> String -> Sender msg
send url id =
    Sock.LowLevel.send url id

init : Sender msg -> String -> String -> String -> Cmd msg
init sender retroId name token =
    sender "init" <|
        Encode.object
            [ ("retroId", Encode.string retroId)
            , ("name", Encode.string name)
            , ("token", Encode.string token)
            ]

add : Sender msg -> String -> String -> Cmd msg
add sender columnId cardText =
     sender "add" <|
        Encode.object
            [ ("columnId", Encode.string columnId)
            , ("cardText", Encode.string cardText)
            ]

move : Sender msg -> String -> String -> String -> Cmd msg
move sender columnFrom columnTo cardId =
    sender "move" <|
        Encode.object
            [ ("columnFrom", Encode.string columnFrom)
            , ("columnTo", Encode.string columnTo)
            , ("cardId", Encode.string cardId)
            ]

stage : Sender msg -> String -> Cmd msg
stage sender stage =
    sender "stage" <|
        Encode.object
            [ ("stage", Encode.string stage)
            ]

reveal : Sender msg -> String -> String -> Cmd msg
reveal sender columnId cardId =
    sender "reveal" <|
        Encode.object
            [ ("columnId", Encode.string columnId)
            , ("cardId", Encode.string cardId)
            ]

group : Sender msg -> String -> String -> String -> String -> Cmd msg
group sender columnFrom cardFrom columnTo cardTo =
    sender "group" <|
        Encode.object
            [ ("columnFrom", Encode.string columnFrom)
            , ("cardFrom", Encode.string cardFrom)
            , ("columnTo", Encode.string columnTo)
            , ("cardTo", Encode.string cardTo)
            ]

vote : Sender msg -> String -> String -> Cmd msg
vote sender columnId cardId =
    sender "vote" <|
        Encode.object
            [ ("columnId", Encode.string columnId)
            , ("cardId", Encode.string cardId)
            ]

delete : Sender msg -> String -> String -> Cmd msg
delete sender columnId cardId =
    sender "delete" <|
        Encode.object
            [ ("columnId", Encode.string columnId)
            , ("cardId", Encode.string cardId)
            ]

menu : Sender msg -> Cmd msg
menu sender =
    sender "menu" <|
        Encode.string ""

createRetro : Sender msg -> String -> List String -> Cmd msg
createRetro sender name users =
    sender "createRetro" <|
        Encode.object
            [ ("name", Encode.string name)
            , ("users", Encode.list (List.map Encode.string users))
            ]
