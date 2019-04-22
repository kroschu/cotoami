module App.Types.Graph.Render exposing (addSubgraph, render)

import App.Ports.Graph exposing (Edge, Node, defaultEdge, defaultNode)
import App.Submodels.Context exposing (Context)
import App.Types.Connection exposing (Connection)
import App.Types.Coto exposing (Coto, Cotonoma)
import App.Types.Graph exposing (Graph)
import Dict
import Exts.Maybe exposing (isJust)


render : Context context -> Graph -> Cmd msg
render context graph =
    graph
        |> toTopicGraph
        |> convert context
        |> App.Ports.Graph.renderGraph


addSubgraph : Context context -> Graph -> Cmd msg
addSubgraph context graph =
    graph
        |> toTopicGraph
        |> convert context
        |> App.Ports.Graph.addSubgraph


convert : Context context -> Graph -> App.Ports.Graph.Model
convert context graph =
    let
        rootNode =
            convertCurrentCotonoma context

        cotoNodes =
            graph.cotos
                |> Dict.values
                |> List.map (convertCoto graph)

        rootConnections =
            graph.rootConnections
                |> List.map (convertConnection rootNode.id)

        connections =
            graph.connections
                |> Dict.toList
                |> List.map
                    (\( sourceId, conns ) ->
                        List.map (convertConnection sourceId) conns
                    )
                |> List.concat

        ( edges, phraseNodes ) =
            (rootConnections ++ connections)
                |> List.foldl (\( e1, n1 ) ( e2, n2 ) -> ( e1 ++ e2, n1 ++ n2 )) ( [], [] )
    in
    { rootNodeId = rootNode.id
    , nodes = rootNode :: (cotoNodes ++ phraseNodes)
    , edges = edges
    }


convertCurrentCotonoma : Context context -> Node
convertCurrentCotonoma context =
    context.cotonoma
        |> Maybe.map
            (\cotonoma ->
                { defaultNode
                    | id = cotonoma.cotoId
                    , label = cotonoma.name
                    , asCotonoma = True
                    , imageUrl = Maybe.map .avatarUrl cotonoma.owner
                }
            )
        |> Maybe.withDefault { defaultNode | id = "home" }


convertCoto : Graph -> Coto -> Node
convertCoto graph coto =
    { defaultNode
        | id = coto.id
        , label = App.Types.Coto.toTopic coto |> Maybe.withDefault ""
        , pinned = App.Types.Graph.pinned coto.id graph
        , asCotonoma = isJust coto.asCotonoma
        , imageUrl = Maybe.map .avatarUrl coto.amishi
        , incomings = coto.incomings |> Maybe.withDefault 0
        , outgoings = coto.outgoings |> Maybe.withDefault 0
    }


convertConnection : String -> Connection -> ( List Edge, List Node )
convertConnection sourceId connection =
    connection.linkingPhrase
        |> Maybe.map
            (\linkingPhrase ->
                let
                    phraseNodeId =
                        sourceId ++ "-" ++ connection.end
                in
                ( [ App.Ports.Graph.initEdgeToLinkingPhrase sourceId phraseNodeId
                  , App.Ports.Graph.initEdgeFromLinkingPhrase phraseNodeId connection.end
                  ]
                , [ { defaultNode
                        | id = phraseNodeId
                        , label = linkingPhrase
                        , asLinkingPhrase = True
                    }
                  ]
                )
            )
        |> Maybe.withDefault
            ( [ App.Ports.Graph.initEdge sourceId connection.end ]
            , []
            )


toTopicGraph : Graph -> Graph
toTopicGraph graph =
    let
        topicCotos =
            graph.cotos
                |> Dict.filter
                    (\cotoId coto ->
                        isJust (App.Types.Coto.toTopic coto)
                    )
    in
    { graph | cotos = topicCotos }
        |> deleteInvalidConnections
        |> excludeUnreachables


excludeUnreachables : Graph -> Graph
excludeUnreachables graph =
    let
        reachableCotos =
            Dict.filter
                (\cotoId coto -> App.Types.Graph.reachableFromPins cotoId graph)
                graph.cotos
    in
    { graph | cotos = reachableCotos }
        |> deleteInvalidConnections


deleteInvalidConnections : Graph -> Graph
deleteInvalidConnections graph =
    let
        rootConnections =
            graph.rootConnections
                |> List.filter (\conn -> Dict.member conn.end graph.cotos)

        connections =
            graph.connections
                |> Dict.toList
                |> List.filterMap
                    (\( sourceId, conns ) ->
                        if Dict.member sourceId graph.cotos then
                            Just
                                ( sourceId
                                , List.filter
                                    (\conn -> Dict.member conn.end graph.cotos)
                                    conns
                                )

                        else
                            Nothing
                    )
                |> Dict.fromList
    in
    { graph | rootConnections = rootConnections, connections = connections }
