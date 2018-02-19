module Cards exposing (..)

import Json.Decode as Decode exposing (Decoder, field, succeed, at, int, string, list, decodeString)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as JD
import InfiniteScroll as IS
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Material
import Material.Options exposing (css)
import Material.Card as Card
import Material.Color as Color
import Material.Options as Options exposing (cs, css)
import Material.Options as Options
import Html exposing (p)
import Material.Elevation as Elevation
import Navigation
import Dict exposing (..)
import Material.Button as Button
import Material.Icon as Icon


-- MODEL


type alias Category =
    { name : String
    , slug : String
    }


type alias Author =
    { name : String
    , url : String
    , avatar : String
    }


type alias Post =
    { id : Int
    , title : String
    , link : String
    , published : String
    , image : String
    , category : Category
    , author : Author
    }


type alias AppModel =
    { posts : List Post
    , error : String
    , infiniteScroll : IS.Model Msg
    , page : Int
    , mdl : Material.Model

    -- a dictionary of post.id and current card elevation value
    , raised : Dict Int Int
    }


type alias Card =
    AppModel -> ( Html Msg, String, Maybe (Html Msg) )


type alias Mdl =
    Material.Model


initialModel : AppModel
initialModel =
    AppModel [] "" (IS.init loadMore |> IS.offset 5 |> IS.direction IS.Bottom) 1 Material.model (Dict.fromList [])


type Msg
    = NewPosts (Result Http.Error (List Post))
    | InfiniteScrollMsg IS.Msg
    | Raise Post Int
    | ClickPost Post
    | Mdl (Material.Msg Msg)


margin1 : Options.Property a b
margin1 =
    css "margin" "0"


margin2 : Options.Property a b
margin2 =
    css "margin" "4px 8px 4px 0px"


optionsValue : Options.Property c Msg -> Post -> Int -> Options.Property c Msg
optionsValue elev post k =
    [ elev
    , Elevation.transition 300
    , Options.onMouseEnter (Raise post k)
    , Options.onMouseLeave (Raise post -1)
    ]
        |> Options.many


dynamic : Int -> AppModel -> Post -> Options.Style Msg
dynamic k model post =
    let
        raised =
            Dict.get post.id model.raised
    in
        case raised of
            Just value ->
                if value == k then
                    optionsValue Elevation.e8 post k
                else
                    optionsValue Elevation.e2 post k

            Nothing ->
                optionsValue Elevation.e2 post k



-- DECODER


postDecoder : Decoder Post
postDecoder =
    decode Post
        |> Json.Decode.Pipeline.required "id" int
        |> Json.Decode.Pipeline.required "title" string
        |> Json.Decode.Pipeline.required "link" string
        |> Json.Decode.Pipeline.required "pubDate" string
        |> Json.Decode.Pipeline.required "thumbnail" string
        |> Json.Decode.Pipeline.required "category" categoryDecoder
        |> Json.Decode.Pipeline.required "author" authorDecoder


categoryDecoder : Decoder Category
categoryDecoder =
    decode Category
        |> Json.Decode.Pipeline.required "name" string
        |> Json.Decode.Pipeline.required "slug" string


authorDecoder : Decoder Author
authorDecoder =
    decode Author
        |> Json.Decode.Pipeline.required "name" string
        |> Json.Decode.Pipeline.required "url" string
        |> Json.Decode.Pipeline.required "author_avatar" string



-- ACTION


postsUrl : String
postsUrl =
    "http://localhost:3000/posts/?_limit=8"


loadMore : IS.Direction -> Cmd Msg
loadMore dir =
    load postsUrl


loadMorePage : Int -> Cmd Msg
loadMorePage page =
    load (postsUrl ++ "&_page=" ++ (toString page))


load : String -> Cmd Msg
load url =
    (Decode.list postDecoder)
        |> Http.get url
        |> Http.send NewPosts


init : ( AppModel, Cmd Msg )
init =
    let
        model =
            initialModel
    in
        ( { model | infiniteScroll = IS.startLoading model.infiniteScroll }, (loadMorePage 1) )



-- UPDATE


update : Msg -> AppModel -> ( AppModel, Cmd Msg )
update msg model =
    case msg of
        Mdl msg_ ->
            Material.update Mdl msg_ model

        InfiniteScrollMsg msg_ ->
            let
                ( infiniteScroll, cmd ) =
                    IS.update InfiniteScrollMsg msg_ model.infiniteScroll

                _ =
                    Debug.log ("invoked infinitescroll!")

                newInfiniteScroll =
                    infiniteScroll |> IS.loadMoreCmd (\_ -> loadMorePage model.page)
            in
                ( { model | infiniteScroll = newInfiniteScroll }, cmd )

        NewPosts (Ok tmpPosts) ->
            let
                _ =
                    Debug.log ("Posts: " ++ (toString tmpPosts))

                newRaisedList =
                    List.map (\p -> ( p.id, -1 )) tmpPosts

                newRaisedDict =
                    Dict.fromList newRaisedList

                infiniteScroll =
                    IS.stopLoading model.infiniteScroll
            in
                ( { model
                    | posts = model.posts ++ tmpPosts
                    , infiniteScroll = infiniteScroll
                    , page = model.page + 1
                    , raised = Dict.union model.raised newRaisedDict
                  }
                , Cmd.none
                )

        NewPosts (Err error) ->
            let
                message =
                    Debug.log ("Error: " ++ (toString error))

                infiniteScroll =
                    IS.stopLoading model.infiniteScroll
            in
                ( { model | error = (toString error), infiniteScroll = infiniteScroll }, Cmd.none )

        Raise post k ->
            let
                newRaised =
                    Dict.insert post.id k model.raised
            in
                ( { model | raised = newRaised }, Cmd.none )

        ClickPost post ->
            ( model, Navigation.load post.link )



-- VIEW


view : AppModel -> Html Msg
view model =
    div
        [ class "cardmvcwrapper" ]
        [ section
            [ class "cardsapp" ]
            [ viewEntries model
            ]
        , infoFooter model
        ]


viewEntries : AppModel -> Html Msg
viewEntries model =
    div
        [ class "main"
        , IS.infiniteScroll InfiniteScrollMsg
        ]
        [ div [] <|
            List.map (viewEntry model) model.posts
        , (loader model)
        ]


white : Options.Property c m
white =
    Color.text Color.white


wide : Float
wide =
    400


viewEntry : AppModel -> Post -> Html Msg
viewEntry model post =
    let
        imageUrl =
            "url('" ++ post.image ++ "') repeat scroll center center / cover"
    in
        Card.view
            [ css "width" (toString wide ++ "px")
            , Color.background (Color.color Color.LightBlue Color.S400)
            , css "flex-direction" "column"
            , css "display" "flex"
            , dynamic 5 model post
            , css "margin" "20px auto 10px auto"
            , Options.onClick (ClickPost post)
            ]
            [ Card.media
                [ css "background" imageUrl
                , css "min-height" "130px"
                , css "min-width" "400px"
                ]
                []
            , Card.title
                [ css "margin-bottom" "20px"
                , css "justify-content" "flex-end"
                ]
                [ Card.head
                    [ white
                    , css "margin-bottom" "2px"
                    ]
                    [ text post.title ]
                , Card.subhead [ white ] [ text post.author.name ]
                ]
            ]


infoFooter : AppModel -> Html msg
infoFooter model =
    footer [ class "info" ]
        [ p [] [ text "Elm App!" ]
        ]


loader : AppModel -> Html Msg
loader model =
    if IS.isLoading model.infiniteScroll then
        div
            [ class "info" ]
            [ text "Loading ..." ]
    else
        div [] []


main : Program Never AppModel Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = (\model -> Sub.none)
        }
