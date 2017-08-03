module App.Messages exposing (Msg(..))

import Http
import Json.Encode exposing (Value)
import Keyboard exposing (..)
import Navigation exposing (Location)
import App.ActiveViewOnMobile exposing (ActiveViewOnMobile)
import App.Types.Coto exposing (Coto, CotoId, Cotonoma, CotonomaKey)
import App.Types.Post exposing (Post)
import App.Types.Amishi exposing (Amishi)
import App.Types.Session exposing (Session)
import App.Types.Graph exposing (Graph)
import Components.ConfirmModal.Messages
import Components.SigninModal
import Components.ProfileModal
import Components.Timeline.Messages
import Components.CotoModal
import Components.CotonomaModal.Messages
import Components.CotoSelection.Messages
import Components.Traversals.Messages


type Msg
    = NoOp
    | OnLocationChange Location
    | NavigationToggle
    | SwitchViewOnMobile ActiveViewOnMobile
    | SessionFetched (Result Http.Error Session)
    | RecentCotonomasFetched (Result Http.Error (List Cotonoma))
    | SubCotonomasFetched (Result Http.Error (List Cotonoma))
    | HomeClick
    | CotonomaFetched (Result Http.Error (Cotonoma, List Amishi, List Post))
    | GraphFetched (Result Http.Error Graph)
    | KeyDown KeyCode
    | KeyUp KeyCode
    | ConfirmModalMsg Components.ConfirmModal.Messages.Msg
    | OpenSigninModal
    | SigninModalMsg Components.SigninModal.Msg
    | OpenProfileModal
    | ProfileModalMsg Components.ProfileModal.Msg
    | TimelineMsg Components.Timeline.Messages.Msg
    | CotoModalMsg Components.CotoModal.Msg
    | DeleteCoto Coto
    | CotoDeleted (Result Http.Error String)
    | OpenCotonomaModal
    | CotonomaModalMsg Components.CotonomaModal.Messages.Msg
    | CotoClick CotoId
    | CotoMouseEnter CotoId
    | CotoMouseLeave CotoId
    | OpenCoto Coto
    | SelectCoto CotoId
    | OpenTraversal CotoId
    | CotonomaClick CotonomaKey
    | ConfirmUnpinCoto CotoId
    | UnpinCoto CotoId
    | CotoUnpinned (Result Http.Error String)
    | CotonomaPresenceState Value
    | CotonomaPresenceDiff Value
    | CotoSelectionMsg Components.CotoSelection.Messages.Msg
    | CloseConnectModal
    | Connect Coto (List Coto)
    | TraversalMsg Components.Traversals.Messages.Msg