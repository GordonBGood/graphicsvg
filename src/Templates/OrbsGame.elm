{-
   OrbsGame - a Physics-based game template written in Elm, using GraphicSVG.
   Created by Chris Schankula (GitHub.com/CSchank).
   First released on March 18th, 2017, for use in can{CODE} 2017 Computer Science conference at McMaster University.
   Modified to update to Elm version 0.19 on September 27, 2018, by W. Gordon Goodsman.
-}


module Main exposing (Ball(..), BallType(..), BallView, Barrier(..), BarrierType(..), CustomBallType(..), EndArea(..), EndAreaType(..), Game, GameState(..), Height, Level, LevelForm, Levels, Model, Msg(..), Position, Radius, Size, Speed, StartingArea(..), UninitializedLevel, UninitializedLevels, Width, XPosition, XSpeed, YPosition, YSpeed, ballView, blankBall, blankLevel, checkArea, checkBarrierCollisions, checkCollisions, checkHitArea, checkInside, checkInsides, checkWalls, checkWin, createSphere, debugText, diss, dropWhile, exampleLevel1, exampleLevel2, exampleLevel3, exampleLevel4, exampleLevel5, exampleLevel6, findBarrierCollision, findCollision, fps, game, growShrinkBarrier, initModel, main, newGrey, newLevel, nextButton, orbsGameApp, processBarrierCollision, processCollision, processInside, refreshButton, screw, slowDown, speedUp, staticBarrier, takeWhile, ui, update, updatePositions, view)

import Dict
import GraphicSVG exposing (..)
import GraphicSVG.App exposing (GameApp, GetKeyState, gameApp)
import List
import String
import Tuple exposing (first)



--application types - not needed for game template API.


type Msg
    = Tick Float GetKeyState
    | ResetLevel
    | MouseOver StartingArea ( Float, Float )
    | MouseLeave
    | StartDrag StartingArea ( Float, Float )
    | ContinueDrag StartingArea ( Float, Float )
    | MoveAim ( Float, Float )
    | LaunchBall ( Float, Float )
    | NextLevel


type GameState
    = MainMenu
    | InGame
    | MousingOver StartingArea ( Float, Float )
    | Aiming ( Float, Float ) ( Float, Float )
    | EndOfLevel
    | EndOfGame


type alias LevelForm a =
    { a
        | title : String
        , description : String
        , winMessage : String
        , winScore : Int
        , leftOverBonusScore : Int
        , startingAreas : List StartingArea
        , balls : List Ball
        , barriers : List (Float -> Barrier)
    }


type alias Level =
    LevelForm
        { ballQueue : List Ball
        , endAreas : List ( EndArea, Bool )
        }


type alias Levels =
    List Level


type alias Model =
    { gameState : GameState
    , levels :
        Dict.Dict Int Level
    , originalLevels :
        Dict.Dict Int Level
    , currLevel : Int
    , ballView : BallView
    , width : Float
    , height : Float
    , score : Int
    , time : Float
    }



--types needed for game template (API)


type Ball
    = Ball Radius BallType ( XPosition, YPosition ) ( XSpeed, YSpeed )


type Barrier
    = Barrier ( XPosition, YPosition ) Radius BarrierType


type alias XPosition =
    Float


type alias YPosition =
    Float


type alias Position =
    ( XPosition, YPosition )


type alias XSpeed =
    Float


type alias YSpeed =
    Float


type alias Speed =
    ( XSpeed, YSpeed )


type alias Radius =
    Float


type BarrierType
    = RegularBarrier
    | SpeedUp
    | SlowDown
    | Disappear


type BallType
    = RegularBall
    | CustomBall CustomBallType


type StartingArea
    = StartingArea ( XPosition, YPosition ) ( Width, Height )


type EndArea
    = EndArea ( XPosition, YPosition ) ( Width, Height ) EndAreaType


type EndAreaType
    = Any
    | Specific BallType


type alias Width =
    Float


type alias Height =
    Float


type alias Size =
    ( Width, Height )


type alias BallView =
    CustomBallType -> Color


type alias UninitializedLevel =
    LevelForm
        { ballQueue : List (Position -> Speed -> Ball)
        , endAreas : List EndArea
        }


type alias UninitializedLevels =
    List UninitializedLevel



--game template API code -- change this to add new levels, balls, etc!


type alias Game =
    { levels : List UninitializedLevel
    , ballView : BallView
    }


game : Game
game =
    { levels =
        [ exampleLevel1 --levels go in this list
        , exampleLevel2
        , exampleLevel3
        , exampleLevel4
        , exampleLevel5
        , exampleLevel6
        ]
    , ballView = ballView
    }



-- create custom balls here


type CustomBallType
    = Basketball
    | TennisBall
    | PurpleBall



--after creating a custom ball, give it a colour here!


ballView : CustomBallType -> Color
ballView ball =
    case ball of
        Basketball ->
            lightOrange

        TennisBall ->
            yellow

        PurpleBall ->
            purple



--some preset types of barriers


staticBarrier : Position -> Radius -> BarrierType -> Float -> Barrier
staticBarrier ( x, y ) r bt _ =
    Barrier ( x, y ) r bt


growShrinkBarrier : Position -> Radius -> Radius -> Float -> BarrierType -> Float -> Barrier
growShrinkBarrier ( x, y ) r1 r2 dt bt t =
    Barrier ( x, y ) (r1 + r2 / 2 + r2 / 2 * sin (t * dt)) bt



--new levels must follow this format (browse examples below for more details)
{-
   sampleLevel : UninitializedLevel
   sampleLevel =
       { title = ""
       , description = ""
       , winMessage = ""
       , winScore = 0
       , leftOverBonusScore = 0
       , startingAreas = []
       , balls = []
       , barriers = []
       , ballQueue = []
       , endAreas = []
       }
-}
--some example levels detailing some of the game mechanics.


exampleLevel1 : UninitializedLevel
exampleLevel1 =
    { title = "Starting Out"
    , description =
        "Welcome to Orbs! Drag on the green launch area to launch the orb into the gray goal."
    , winMessage = "Good job! Click the blue next button."
    , winScore = 10
    , leftOverBonusScore = 5
    , startingAreas = [ StartingArea ( 0, -125 ) ( 150, 75 ) ]
    , balls = []
    , barriers = []
    , ballQueue = [ Ball 30 (CustomBall Basketball) ]
    , endAreas = [ EndArea ( 0, 150 ) ( 50, 50 ) Any ]
    }


exampleLevel2 : UninitializedLevel
exampleLevel2 =
    { title = "Colour Matters"
    , description =
        "Non-gray goals must have be touched by the correct colour."
    , winMessage = "Good job! Click the blue next button."
    , winScore = 10
    , leftOverBonusScore = 5
    , startingAreas = [ StartingArea ( 0, -125 ) ( 150, 75 ) ]
    , balls = []
    , barriers = []
    , ballQueue = [ Ball 30 (CustomBall Basketball), Ball 20 RegularBall ]
    , endAreas =
        [ EndArea ( -100, 150 ) ( 50, 50 ) (Specific (CustomBall Basketball))
        , EndArea ( 100, 150 ) ( 50, 50 ) (Specific RegularBall)
        ]
    }


exampleLevel3 : UninitializedLevel
exampleLevel3 =
    { title = "Barrier to Success"
    , description =
        "Outlined circles are barriers that the balls can't get through."
    , winMessage = "Good job! Click the blue next button."
    , winScore = 10
    , leftOverBonusScore = 5
    , startingAreas = [ StartingArea ( 0, -125 ) ( 150, 75 ) ]
    , balls = []
    , barriers = [ staticBarrier ( 0, 0 ) 50 RegularBarrier ]
    , ballQueue = [ Ball 30 (CustomBall Basketball) ]
    , endAreas =
        [ EndArea ( 0, 150 ) ( 50, 50 ) (Specific (CustomBall Basketball)) ]
    }


exampleLevel4 : UninitializedLevel
exampleLevel4 =
    { title = "Collision Course"
    , description = "Balls can be collided into others to change their courses."
    , winMessage = "Good job! Click the blue next button."
    , winScore = 10
    , leftOverBonusScore = 5
    , startingAreas = [ StartingArea ( 0, -125 ) ( 150, 75 ) ]
    , balls = [ Ball 30 RegularBall ( 0, 0 ) ( 100, 0 ) ]
    , barriers = []
    , ballQueue = [ Ball 20 (CustomBall Basketball) ]
    , endAreas =
        [ EndArea ( 0, 150 ) ( 50, 50 ) (Specific RegularBall)
        , EndArea ( 150, -120 ) ( 50, 50 ) (Specific (CustomBall Basketball))
        ]
    }


exampleLevel5 : UninitializedLevel
exampleLevel5 =
    { title = "Special Barriers"
    , description =
        "Red barriers will cause your balls to disappear. Be careful!"
    , winMessage = "Good job! Click the blue next button."
    , winScore = 10
    , leftOverBonusScore = 5
    , startingAreas = [ StartingArea ( 0, -125 ) ( 150, 75 ) ]
    , balls = []
    , barriers =
        [ staticBarrier ( -75, 0 ) 50 Disappear
        , staticBarrier ( 75, 0 ) 50 Disappear
        , staticBarrier ( -200, 0 ) 30 Disappear
        , staticBarrier ( 200, 0 ) 30 Disappear
        ]
    , ballQueue = [ Ball 24 (CustomBall Basketball) ]
    , endAreas =
        [ EndArea ( 0, 150 ) ( 50, 50 ) (Specific (CustomBall Basketball)) ]
    }


exampleLevel6 : UninitializedLevel
exampleLevel6 =
    { title = "Growing and Shrinking"
    , description =
        "Barriers can grow, shrink and / or move around. Good luck!"
    , winMessage = "Good job! Click the blue next button."
    , winScore = 20
    , leftOverBonusScore = 5
    , startingAreas = [ StartingArea ( 0, -125 ) ( 75, 75 ) ]
    , balls = []
    , barriers =
        [ staticBarrier ( 200, 50 ) 30 Disappear
        , growShrinkBarrier ( 0, 50 ) 50 75 2 Disappear
        , staticBarrier ( -200, 50 ) 30 Disappear
        , staticBarrier ( 200, 200 ) 30 RegularBarrier
        , staticBarrier ( -200, 200 ) 30 RegularBarrier
        ]
    , ballQueue =
        [ Ball 24 (CustomBall Basketball), Ball 15 (CustomBall Basketball) ]
    , endAreas =
        [ EndArea ( 0, 150 ) ( 50, 50 ) (Specific (CustomBall Basketball)) ]
    }



--application code, not part of template, edit at own risk.


fps : Float
fps =
    30


newLevel : UninitializedLevel
newLevel =
    { title = ""
    , description = ""
    , winMessage = ""
    , winScore = 0
    , leftOverBonusScore = 0
    , startingAreas = []
    , balls = []
    , barriers = []
    , ballQueue = []
    , endAreas = []
    }


blankLevel : Level
blankLevel =
    { title = ""
    , description = ""
    , winMessage = ""
    , winScore = 0
    , leftOverBonusScore = 0
    , startingAreas = []
    , balls = []
    , barriers = []
    , ballQueue = []
    , endAreas = []
    }


blankBall : Ball
blankBall =
    Ball 0 RegularBall ( 0, 0 ) ( 0, 0 )


checkWalls : Model -> List Ball -> List Ball
checkWalls model balls =
    List.map
        (\(Ball r c ( x, y ) ( xspeed, yspeed )) ->
            if x + r + xspeed / fps > model.width / 2 then
                Ball r c ( x, y ) ( -xspeed, yspeed )

            else if x - r + xspeed / fps < -model.width / 2 then
                Ball r c ( x, y ) ( -xspeed, yspeed )

            else if y + r + yspeed / fps > model.height / 2 then
                Ball r c ( x, y ) ( xspeed, -yspeed )

            else if y - r + yspeed / fps < -model.height / 2 + 75 then
                Ball r c ( x, y ) ( xspeed, -yspeed )

            else
                Ball r c ( x, y ) ( xspeed, yspeed )
        )
        balls


checkCollisions : List Ball -> List Ball
checkCollisions balls =
    List.map first <| List.map (\ball -> findCollision balls ball) balls


findCollision : List Ball -> Ball -> ( Ball, Bool )
findCollision balls ball1 =
    List.foldl
        (\b2 ( b1, collided ) ->
            processCollision collided b1 b2
        )
        ( ball1, False )
        balls


processCollision : Bool -> Ball -> Ball -> ( Ball, Bool )
processCollision collided (Ball r1 c1 ( x1, y1 ) ( xsp1, ysp1 )) (Ball r2 c2 ( x2, y2 ) ( xsp2, ysp2 )) =
    let
        dx =
            (x2 + xsp2 / fps) - (x1 + xsp1 / fps)

        dy =
            (y2 + ysp2 / fps) - (y1 + ysp1 / fps)

        dNow =
            sqrt <| (x2 - x1) ^ 2 - (y2 - y1) ^ 2

        d =
            sqrt <| dx ^ 2 + dy ^ 2

        ( nx, ny ) =
            ( dx / d, dy / d )

        r =
            r1 + r2

        p =
            2
                * 0.94868329805
                * (xsp1 * nx + ysp1 * ny - xsp2 * nx - ysp2 * ny)
                / (r1 ^ 3 + r2 ^ 3)
    in
    if d < r && (x1 /= x2 || y1 /= y2) && not collided then
        ( Ball
            r1
            c1
            ( x1, y1 )
            ( xsp1 - p * r2 ^ 3 * nx
            , ysp1 - p * r2 ^ 3 * ny
            )
        , True
        )

    else
        ( Ball r1 c1 ( x1, y1 ) ( xsp1, ysp1 ), collided )


checkBarrierCollisions : Model -> List (Float -> Barrier) -> List Ball -> List Ball
checkBarrierCollisions model barriers balls =
    findBarrierCollision model barriers balls


findBarrierCollision : Model -> List (Float -> Barrier) -> List Ball -> List Ball
findBarrierCollision model barriers balls =
    case balls of
        ball :: rest ->
            processBarrierCollision model barriers ball
                ++ findBarrierCollision model barriers rest

        [] ->
            []


processBarrierCollision : Model -> List (Float -> Barrier) -> Ball -> List Ball
processBarrierCollision model barriers ball =
    let
        (Ball balr balc ( balx, baly ) ( xsp, ysp )) =
            ball

        barrier =
            case List.head barriers of
                Just x ->
                    x model.time

                Nothing ->
                    Barrier ( 0, 0 ) 0 RegularBarrier

        rest =
            List.drop 1 barriers
    in
    case barrier of
        Barrier ( barx, bary ) barr bart ->
            let
                dx =
                    (balx + xsp / fps) - barx

                dy =
                    (baly + ysp / fps) - bary

                d =
                    sqrt <| dx ^ 2 + dy ^ 2

                ( nx, ny ) =
                    ( dx / d, dy / d )

                r =
                    balr + barr

                p =
                    xsp * nx + ysp * ny
            in
            if (d < r) && barr /= 0 then
                case bart of
                    RegularBarrier ->
                        [ Ball
                            balr
                            balc
                            ( balx, baly )
                            ( xsp - 2 * p * nx, ysp - 2 * p * ny )
                        ]

                    SpeedUp ->
                        [ Ball
                            balr
                            balc
                            ( balx, baly )
                            ( xsp - 2 * sqrt 1.1 * p * nx
                            , ysp - 2 * sqrt 1.1 * p * ny
                            )
                        ]

                    SlowDown ->
                        [ Ball
                            balr
                            balc
                            ( balx, baly )
                            ( xsp - 2 * sqrt (1 / 1.1) * p * nx
                            , ysp - 2 * sqrt (1 / 1.1) * p * ny
                            )
                        ]

                    Disappear ->
                        []

            else if List.length rest == 0 then
                [ ball ]

            else
                processBarrierCollision model rest ball


checkInsides : Model -> List Ball -> List Ball
checkInsides model balls =
    List.map first <| List.map (\ball -> checkInside model balls ball) balls


checkInside : Model -> List Ball -> Ball -> ( Ball, Bool )
checkInside model balls ball1 =
    List.foldl
        (\b2 ( b1, moved ) ->
            processInside model moved b1 b2
        )
        ( ball1, False )
        balls


processInside : Model -> Bool -> Ball -> Ball -> ( Ball, Bool )
processInside model moved (Ball r1 c1 ( x1, y1 ) ( xsp1, ysp1 )) (Ball r2 c2 ( x2, y2 ) ( xsp2, ysp2 )) =
    let
        dx =
            x2 - x1

        dy =
            y2 - y1

        d =
            sqrt <| dx ^ 2 + dy ^ 2

        r =
            r1 + r2
    in
    if
        d
            < r
            && not moved
            && (x1
                    /= x2
                    || y1
                    /= y2
               )
            && r1
            <= r2
    then
        ( Ball r1
            c1
            ( x1 - dx * 1.2
            , y1 - dy * 1.2
            )
            ( xsp1, ysp1 )
        , True
        )

    else if x1 + r1 > model.width / 2 then
        ( Ball
            r1
            c1
            ( x1 - (r1 + x1 - model.width / 2) * 1.2, y1 )
            ( xsp1, ysp1 )
        , True
        )

    else if x1 - r1 < -model.width / 2 then
        ( Ball
            r1
            c1
            ( x1 + (r1 + x1 - model.width / 2) * 1.2, y1 )
            ( xsp1, ysp1 )
        , True
        )

    else if y1 + r1 > model.height / 2 then
        ( Ball
            r1
            c1
            ( x1, y1 - (r1 + y1 - model.height / 2) * 1.2 )
            ( xsp1, ysp1 )
        , True
        )

    else if y1 - r1 < -model.height / 2 + 75 then
        ( Ball
            r1
            c1
            ( x1, y1 + (r1 + y1 - model.height / 2) * 1.2 )
            ( xsp1, ysp1 )
        , True
        )

    else
        ( Ball r1 c1 ( x1, y1 ) ( xsp1, ysp1 ), moved )


checkHitArea : Level -> List ( EndArea, Bool )
checkHitArea level =
    let
        balls =
            level.balls
    in
    List.map
        (\( endArea, c ) ->
            List.foldl checkArea ( endArea, c ) balls
        )
        level.endAreas


checkArea : Ball -> ( EndArea, Bool ) -> ( EndArea, Bool )
checkArea (Ball br bt ( bx, by ) _) ( EndArea ( ex, ey ) ( ew, eh ) ebt, success ) =
    let
        correctBall =
            case ebt of
                Any ->
                    True

                Specific s ->
                    s == bt
    in
    if success then
        ( EndArea ( ex, ey ) ( ew, eh ) ebt, success )

    else if
        correctBall
            && (bx + br > ex - ew / 2)
            && (bx - br < ex + ew / 2)
            && (by + br > ey - eh / 2)
            && (by - br < ey + eh / 2)
    then
        ( EndArea ( ex, ey ) ( ew, eh ) ebt, True )

    else
        ( EndArea ( ex, ey ) ( ew, eh ) ebt, success )


checkWin : Level -> Bool
checkWin level =
    List.all (\( _, b ) -> b) level.endAreas


createSphere : Model -> Ball -> Shape Msg
createSphere model (Ball r c ( x, y ) _) =
    group
        [ circle r
            |> filled
                (case c of
                    RegularBall ->
                        red

                    CustomBall bt ->
                        model.ballView bt
                )
        , oval (r * 0.8) (r * 0.3)
            |> filled white
            |> rotate (degrees -45)
            |> move ( r / 2, r / 2 )
            |> makeTransparent 0.3
        ]
        |> move ( x, y )


ui :
    Model
    -> Level
    -> Shape Msg -- this is an inner annotation, can't do it
ui model olevel =
    let
        ( txt, col ) =
            case model.gameState of
                InGame ->
                    ( olevel.description, black )

                Aiming _ _ ->
                    ( olevel.description, black )

                MousingOver _ _ ->
                    ( olevel.description, black )

                EndOfLevel ->
                    ( olevel.winMessage, green )

                _ ->
                    ( "", blank )

        line1 =
            String.join " " <| takeWhile 32 0 <| String.words txt

        line2 =
            String.join " " <|
                takeWhile 32 0 <|
                    dropWhile 32 0 <|
                        String.words txt

        line3 =
            String.join " " <|
                takeWhile 29 0 <|
                    dropWhile 61 0 <|
                        String.words txt

        line4 =
            String.join " " <|
                takeWhile 29 0 <|
                    dropWhile 90 0 <|
                        String.words txt

        level =
            case Dict.get model.currLevel model.levels of
                Just lvl ->
                    lvl

                Nothing ->
                    blankLevel
    in
    group
        [ rect 500 75 |> filled white
        , case model.gameState of
            InGame ->
                refreshButton |> move ( 230, -25 ) |> notifyTap ResetLevel

            MousingOver _ _ ->
                refreshButton |> move ( 230, -25 ) |> notifyTap ResetLevel

            Aiming _ _ ->
                refreshButton |> move ( 230, -25 ) |> notifyTap ResetLevel

            EndOfLevel ->
                nextButton |> move ( 230, -25 ) |> notifyTap NextLevel

            _ ->
                group []
        , roundedRect 190 25 10 |> filled grey |> move ( -140, 12.5 )
        , roundedRect 50 50 10 |> filled grey |> move ( -40, 0 )
        , group
            (List.indexedMap
                (\n (Ball r c _ _) ->
                    if n < 9 then
                        group
                            [ createSphere model (Ball r c ( 0, 0 ) ( 0, 0 ))
                            , text (String.fromFloat r)
                                |> centered
                                |> fixedwidth
                                |> size 24
                                |> filled white
                                |> move ( 0, -8 )
                            ]
                            |> move
                                ( if n == 0 then
                                    -40

                                  else
                                    toFloat n * -20 - 60
                                , if n == 0 then
                                    0

                                  else
                                    12
                                )
                            |> scale
                                (if n == 0 then
                                    20 / r

                                 else
                                    8 / r
                                )

                    else
                        group []
                )
                level.ballQueue
            )
        , text
            ("Score: "
                ++ String.fromInt model.score
            )
            |> size 14
            |> fixedwidth
            |> filled black
            |> move ( -240, -30 )
        , text "Launch Queue"
            |> size 12
            |> fixedwidth
            |> filled black
            |> move ( -190, -12 )
        , text line1 |> fixedwidth |> filled col
        , text line2 |> fixedwidth |> filled col |> move ( 0, -10 )
        , text line3 |> fixedwidth |> filled col |> move ( 0, -20 )
        , text
            (if String.length line4 > 29 then
                String.left 26 line4 ++ "..."

             else
                line4
            )
            |> fixedwidth
            |> filled col
            |> move ( 0, -30 )
        , text
            ("Level "
                ++ String.fromInt (model.currLevel + 1)
                ++ ": "
                ++ olevel.title
            )
            |> fixedwidth
            |> size 14
            |> filled black
            |> move ( 0, 15 )
        ]


takeWhile : Int -> Int -> List String -> List String
takeWhile n len words =
    let
        loop l wrds lst =
            case wrds of
                word :: rest ->
                    let
                        newLength =
                            l + String.length word + 1
                    in
                    if newLength <= n then
                        loop newLength rest (word :: lst)

                    else
                        List.reverse lst

                [] ->
                    List.reverse lst
    in
    loop len words []


dropWhile : Int -> Int -> List String -> List String
dropWhile n len words =
    let
        loop l wrds lst =
            case wrds of
                word :: rest ->
                    let
                        newLength =
                            l + String.length word + 1
                    in
                    if newLength <= n then
                        loop newLength rest lst

                    else
                        loop newLength rest (word :: lst)

                [] ->
                    List.reverse lst
    in
    loop len words []


screw : Shape Msg
screw =
    group
        [ circle 25 |> filled lightGrey
        , circle 20 |> filled grey
        , rect 35 5 |> filled newGrey
        , rect 5 35 |> filled newGrey
        ]
        |> scale (1 / 25)


diss : Shape Msg
diss =
    group
        [ rect 35 (25 / 4) |> filled white
        , rect (25 / 4) 35 |> filled white
        ]
        |> rotate (degrees 45)
        |> scale (1 / 25)


speedUp : Shape Msg
speedUp =
    group
        [ group
            [ rect 20 (25 / 4)
                |> filled newGrey
                |> move ( -5, 5 )
                |> rotate (degrees -45)
            , rect 20 (25 / 4)
                |> filled newGrey
                |> move ( -5, -5 )
                |> rotate (degrees 45)
            , rect 20 (25 / 4)
                |> filled newGrey
                |> move ( 30 / 4, 5 )
                |> rotate (degrees -45)
            , rect 20 (25 / 4)
                |> filled newGrey
                |> move ( 30 / 4, -5 )
                |> rotate (degrees 45)
            ]
        ]
        |> scale (1 / 25)


slowDown : Shape Msg
slowDown =
    speedUp |> scaleY -1


newGrey : Color
newGrey =
    rgb 255 255 255


refreshButton : Shape Msg
refreshButton =
    group
        [ roundedRect 25 25 5 |> filled lightOrange
        , circle 7 |> outlined (solid 3) white
        , rect 10 5
            |> filled lightOrange
            |> rotate (degrees 30)
            |> move ( -5, 0 )
        , triangle 5 |> filled white |> move ( -6.5, 2 )
        ]


nextButton : Shape Msg
nextButton =
    group
        [ roundedRect 25 25 5 |> filled lightBlue
        , triangle 6 |> filled white |> move ( 3, 0 )
        , rect 12 5 |> filled white |> move ( -1, 0 )
        ]


initModel : Game -> Model
initModel input =
    { gameState = InGame
    , levels =
        Dict.fromList
            (List.indexedMap
                (\n level ->
                    let
                        lvlTup =
                            { blankLevel
                                | title = level.title
                                , description = level.description
                                , winMessage = level.winMessage
                                , winScore = level.winScore
                                , leftOverBonusScore = level.leftOverBonusScore
                                , startingAreas = level.startingAreas
                                , balls = level.balls
                                , barriers = level.barriers
                                , endAreas =
                                    List.map
                                        (\endArea -> ( endArea, False ))
                                        level.endAreas
                                , ballQueue =
                                    List.map
                                        (\pb -> pb ( 0, 0 ) ( 0, 0 ))
                                        level.ballQueue
                            }
                    in
                    ( n, lvlTup )
                )
                input.levels
            )
    , originalLevels =
        Dict.fromList
            (List.indexedMap
                (\n level ->
                    let
                        lvlTup =
                            { blankLevel
                                | title = level.title
                                , description = level.description
                                , winMessage = level.winMessage
                                , winScore = level.winScore
                                , leftOverBonusScore = level.leftOverBonusScore
                                , startingAreas = level.startingAreas
                                , balls = level.balls
                                , barriers = level.barriers
                                , endAreas =
                                    List.map
                                        (\endArea -> ( endArea, False ))
                                        level.endAreas
                                , ballQueue =
                                    List.map
                                        (\pb -> pb ( 0, 0 ) ( 0, 0 ))
                                        level.ballQueue
                            }
                    in
                    ( n, lvlTup )
                )
                input.levels
            )
    , currLevel = 0
    , ballView = input.ballView
    , width = 500
    , height = 500
    , score = 0
    , time = 0
    }


updatePositions : List Ball -> List Ball
updatePositions balls =
    List.map
        (\(Ball r c ( x, y ) ( xspeed, yspeed )) ->
            Ball r
                c
                ( x + xspeed / fps, y + yspeed / fps )
                ( xspeed, yspeed )
        )
        balls


update : Msg -> Model -> Model
update msg model =
    let
        level =
            case Dict.get model.currLevel model.levels of
                Just lvl ->
                    lvl

                Nothing ->
                    blankLevel
    in
    case msg of
        Tick t _ ->
            { model
                | levels =
                    Dict.update
                        model.currLevel
                        (\lvel ->
                            case lvel of
                                Just lvl ->
                                    Just
                                        { lvl
                                            | balls =
                                                checkInsides
                                                    model
                                                <|
                                                    updatePositions <|
                                                        checkWalls model <|
                                                            checkBarrierCollisions
                                                                model
                                                                lvl.barriers
                                                            <|
                                                                checkCollisions <|
                                                                    lvl.balls
                                            , endAreas = checkHitArea lvl
                                        }

                                Nothing ->
                                    Just blankLevel
                        )
                        model.levels
                , gameState =
                    case model.gameState of
                        InGame ->
                            if checkWin level then
                                EndOfLevel

                            else
                                model.gameState

                        Aiming _ _ ->
                            if checkWin level then
                                EndOfLevel

                            else
                                model.gameState

                        MousingOver _ _ ->
                            if checkWin level then
                                EndOfLevel

                            else
                                model.gameState

                        _ ->
                            model.gameState
                , score =
                    case model.gameState of
                        InGame ->
                            if checkWin level then
                                model.score
                                    + level.winScore
                                    + List.length level.ballQueue
                                    * level.leftOverBonusScore

                            else
                                model.score

                        Aiming _ _ ->
                            if checkWin level then
                                model.score
                                    + level.winScore
                                    + List.length level.ballQueue
                                    * level.leftOverBonusScore

                            else
                                model.score

                        MousingOver _ _ ->
                            if checkWin level then
                                model.score
                                    + level.winScore
                                    + List.length level.ballQueue
                                    * level.leftOverBonusScore

                            else
                                model.score

                        _ ->
                            model.score
                , time = t
            }

        ResetLevel ->
            let
                origLevel =
                    Dict.get model.currLevel model.originalLevels
            in
            { model
                | levels =
                    Dict.update
                        model.currLevel
                        (\lvel ->
                            case lvel of
                                Just lvl ->
                                    origLevel

                                Nothing ->
                                    origLevel
                        )
                        model.levels
                , gameState = InGame
            }

        MouseOver (StartingArea ( x, y ) ( w, h )) ( mx, my ) ->
            let
                (Ball r _ _ _) =
                    case List.head level.ballQueue of
                        Just b ->
                            b

                        Nothing ->
                            blankBall

                cx =
                    if mx + r < x + w / 2 && mx - r > x - w / 2 then
                        mx

                    else if mx + r > x + w / 2 then
                        x + w / 2 - r

                    else
                        x - w / 2 + r

                cy =
                    if my + r < y + h / 2 && my - r > y - h / 2 then
                        my

                    else if my + r > y + h / 2 then
                        y + h / 2 - r

                    else
                        y - h / 2 + r
            in
            { model
                | gameState =
                    case model.gameState of
                        InGame ->
                            if r * 2 <= w && r * 2 <= h then
                                MousingOver
                                    (StartingArea ( x, y ) ( w, h ))
                                    ( cx, cy )

                            else
                                InGame

                        MousingOver _ _ ->
                            if r * 2 <= w && r * 2 <= h then
                                MousingOver
                                    (StartingArea ( x, y ) ( w, h ))
                                    ( cx, cy )

                            else
                                InGame

                        _ ->
                            model.gameState
            }

        MouseLeave ->
            { model
                | gameState =
                    case model.gameState of
                        MousingOver _ _ ->
                            InGame

                        _ ->
                            model.gameState
            }

        StartDrag (StartingArea _ _) ( mx, my ) ->
            { model
                | gameState =
                    case model.gameState of
                        MousingOver _ ( cx, cy ) ->
                            if List.length level.ballQueue > 0 then
                                Aiming ( cx, cy ) ( mx, my )

                            else
                                model.gameState

                        _ ->
                            model.gameState
            }

        ContinueDrag (StartingArea _ _) _ ->
            model

        MoveAim ( mx, my ) ->
            { model
                | gameState =
                    case model.gameState of
                        Aiming pos _ ->
                            Aiming pos ( mx, my )

                        _ ->
                            model.gameState
            }

        LaunchBall _ ->
            { model
                | gameState =
                    case model.gameState of
                        Aiming _ _ ->
                            InGame

                        _ ->
                            model.gameState
                , levels =
                    Dict.update
                        model.currLevel
                        (\ml ->
                            case ml of
                                Just lvl ->
                                    let
                                        balls =
                                            lvl.balls

                                        firstInQueue =
                                            case List.head lvl.ballQueue of
                                                Just ball ->
                                                    ball

                                                Nothing ->
                                                    blankBall

                                        (Ball r c _ ( vx, vy )) =
                                            firstInQueue
                                    in
                                    case model.gameState of
                                        Aiming ( sx, sy ) ( cx, cy ) ->
                                            Just
                                                { lvl
                                                    | balls =
                                                        lvl.balls
                                                            ++ [ Ball r
                                                                    c
                                                                    ( sx, sy )
                                                                    ( cx - sx, cy - sy )
                                                               ]
                                                    , ballQueue =
                                                        List.drop 1 lvl.ballQueue
                                                }

                                        _ ->
                                            Nothing

                                Nothing ->
                                    Nothing
                        )
                        model.levels
            }

        NextLevel ->
            { model
                | currLevel = model.currLevel + 1
                , gameState = InGame
            }


view : Model -> GraphicSVG Msg
view model =
    let
        level =
            case Dict.get model.currLevel model.levels of
                Just lvl ->
                    lvl

                Nothing ->
                    blankLevel

        (Ball ro _ _ _) =
            case List.head level.ballQueue of
                Just b ->
                    b

                Nothing ->
                    blankBall

        barriers =
            List.map (\barrier -> barrier model.time) level.barriers
    in
    collage model.width
        model.height
        [ graphPaper 50
        , group
            ((case model.gameState of
                MousingOver (StartingArea ( x, y ) ( w, h )) ( mx, my ) ->
                    [ circle ro
                        |> outlined (dashed 1) black
                        |> move ( mx, my )
                    ]

                Aiming ( x1, y1 ) ( x2, y2 ) ->
                    [ circle ro |> outlined (dashed 1) black |> move ( x1, y1 )
                    , line ( x1, y1 ) ( x2, y2 ) |> outlined (solid 1) black
                    ]

                _ ->
                    []
             )
                ++ List.map
                    (\(StartingArea (( x, y ) as pos) (( w, h ) as size)) ->
                        rect w h
                            |> filled green
                            |> move ( x, y )
                            |> makeTransparent 0.4
                            |> notifyMouseDownAt
                                (StartDrag (StartingArea pos size))
                            |> notifyMouseMoveAt
                                (MouseOver (StartingArea pos size))
                            |> notifyLeave MouseLeave
                    )
                    level.startingAreas
            )
        , group
            (List.map
                (\( EndArea ( x, y ) ( w, h ) c, completed ) ->
                    if completed then
                        rect w h
                            |> filled lightGreen
                            |> makeTransparent 0.4
                            |> addOutline (dashed 2)
                                (case c of
                                    Any ->
                                        gray

                                    Specific s ->
                                        case s of
                                            RegularBall ->
                                                red

                                            CustomBall b ->
                                                model.ballView b
                                )
                            |> move ( x, y )

                    else
                        rect w h
                            |> outlined
                                (dashed 2)
                                (case c of
                                    Any ->
                                        gray

                                    Specific s ->
                                        case s of
                                            RegularBall ->
                                                red

                                            CustomBall b ->
                                                model.ballView b
                                )
                            |> move ( x, y )
                )
                level.endAreas
            )
        , group
            (List.map
                (\(Ball r c ( x, y ) _) ->
                    createSphere model (Ball r c ( x, y ) ( 0, 0 ))
                )
                level.balls
            )
        , group
            (List.map
                (\barrier ->
                    case barrier of
                        Barrier ( x, y ) r b ->
                            case b of
                                RegularBarrier ->
                                    group
                                        [ circle r
                                            |> filled lightGray
                                            |> addOutline (solid 1) black
                                        , screw
                                            |> scale
                                                (if r > 25 then
                                                    10

                                                 else
                                                    r / 5
                                                )
                                        ]
                                        |> move ( x, y )

                                SpeedUp ->
                                    group
                                        [ circle r
                                            |> filled darkGreen
                                            |> addOutline (solid 1) black
                                        , speedUp
                                            |> scale
                                                (if r > 25 then
                                                    10

                                                 else
                                                    r / 5
                                                )
                                        ]
                                        |> move ( x, y )

                                SlowDown ->
                                    group
                                        [ circle r
                                            |> filled yellow
                                            |> addOutline (solid 1) black
                                        , slowDown
                                            |> scale
                                                (if r > 25 then
                                                    10

                                                 else
                                                    r / 5
                                                )
                                            |> move ( -1, 0 )
                                        ]
                                        |> move ( x, y )

                                Disappear ->
                                    group
                                        [ circle r
                                            |> filled red
                                            |> addOutline (solid 1) black
                                        , diss
                                            |> scale
                                                (if r > 25 then
                                                    10

                                                 else
                                                    r / 5
                                                )
                                        ]
                                        |> move ( x, y )
                )
                barriers
            )
        , case model.gameState of
            Aiming ( _, _ ) ( mx, my ) ->
                circle 100
                    |> filled blank
                    |> move ( mx, my )
                    |> notifyMouseMoveAt MoveAim
                    |> notifyMouseUpAt LaunchBall

            _ ->
                group []
        , ui model level |> move ( 0, -212.5 )

        --        , debugText model
        ]


debugText x =
    let
        s =
            Debug.toString x

        apart n str out =
            if String.isEmpty str then
                group <| List.reverse out

            else
                apart (n + 10)
                    (String.dropLeft 160 str)
                    ((String.left 160 str |> text |> size 7 |> filled black |> move ( -250, 225 - n )) :: out)
    in
    apart 0 s []


orbsGameApp : Game -> GameApp Model Msg
orbsGameApp input =
    gameApp
        Tick
        { model = initModel input
        , update = update
        , view = view
        }


main : GameApp Model Msg
main =
    orbsGameApp game
