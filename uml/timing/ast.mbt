///|
/// The kind of a timing-diagram player, mirroring PlantUML's `Player`
/// subclasses and the `TimingStyle` enum used by `CommandRobustConcise`.
pub(all) enum PlayerKind {
  Robust
  Concise
  Rectangle
  Binary
  Clock
  Analog
} derive(Eq, Debug)

///|
pub extend PlayerKind with Eq::{not_equal, equal}

///|
pub extend PlayerKind with Debug::{to_repr}

///|
/// The display format attached to a `TimeTick`, mirroring `TimingFormat`.
///
/// The format only affects how a time value is rendered; parsing keeps the
/// exact decimal value independently of it.
pub(all) enum TimingFormat {
  Decimal
  Hour
  Date
} derive(Eq, Debug)

///|
pub extend TimingFormat with Eq::{not_equal, equal}

///|
pub extend TimingFormat with Debug::{to_repr}

///|
/// The time-axis strategy selected by `hide time axis` and `manual time axis`,
/// mirroring `TimeAxisStategy`.
pub(all) enum TimeAxisStrategy {
  Automatic
  Manual
  Hidden
} derive(Eq, Debug)

///|
pub extend TimeAxisStrategy with Eq::{not_equal, equal}

///|
pub extend TimeAxisStrategy with Debug::{to_repr}

///|
/// An exact decimal time value, mirroring the `BigDecimal` carried by
/// `TimeTick` in the Java implementation.
pub struct Decimal {
  sign : Int
  coeff : String
  scale : Int
} derive(Eq, Debug)

///|
pub extend Decimal with Eq::{not_equal, equal}

///|
pub extend Decimal with Debug::{to_repr}

///|
pub struct TimeTick {
  time : Decimal
  format : TimingFormat
} derive(Eq, Debug)

///|
pub extend TimeTick with Eq::{not_equal, equal}

///|
pub extend TimeTick with Debug::{to_repr}

///|
/// A state change recorded on a player, mirroring `ChangeState`.
///
/// `when` is the tick the change applies at; the initial state is the change
/// recorded before any time mark exists, and keeps `when = None`.
pub struct ChangeState {
  when : TimeTick?
  comment : String?
  color : String?
  states : Array[String]
} derive(Eq, Debug)

///|
pub extend ChangeState with Eq::{not_equal, equal}

///|
pub extend ChangeState with Debug::{to_repr}

///|
pub struct TimingNote {
  when : TimeTick?
  position : String
  text : String
  stereotype : String?
} derive(Eq, Debug)

///|
pub extend TimingNote with Eq::{not_equal, equal}

///|
pub extend TimingNote with Debug::{to_repr}

///|
pub struct TimeConstraint {
  tick1 : TimeTick
  tick2 : TimeTick
  message : String?
  style : String?
} derive(Eq, Debug)

///|
pub extend TimeConstraint with Eq::{not_equal, equal}

///|
pub extend TimeConstraint with Debug::{to_repr}

///|
/// A message drawn between two players, mirroring `TimeMessage`.
///
/// Player endpoints are kept as codes; the tick of an endpoint is null when
/// the optional `@time` expression was absent or unresolved.
pub struct TimingMessage {
  player1 : String
  tick1 : TimeTick?
  player2 : String
  tick2 : TimeTick?
  label : String?
  style : String?
} derive(Eq, Debug)

///|
pub extend TimingMessage with Eq::{not_equal, equal}

///|
pub extend TimingMessage with Debug::{to_repr}

///|
pub struct Highlight {
  from : TimeTick?
  to : TimeTick?
  caption : String?
  color : String?
} derive(Eq, Debug)

///|
pub extend Highlight with Eq::{not_equal, equal}

///|
pub extend Highlight with Debug::{to_repr}

///|
/// A parsed timing player, mirroring the `Player` subclasses.
///
/// Kind-specific data lives in dedicated fields: `states` holds the
/// code-to-label mapping of state players, `period`/`pulse`/`offset` belong to
/// clocks, and `bounds`/`ticks_every` to analog players.
pub struct TimingPlayer {
  code : String
  title : String
  kind : PlayerKind
  compact : Bool
  stereotype : String?
  background_color : String?
  states : Array[(String, String)]
  mut initial : ChangeState?
  changes : Array[ChangeState]
  notes : Array[TimingNote]
  constraints : Array[TimeConstraint]
  period : String?
  pulse : String?
  offset : String?
  mut bounds : (String, String)?
  mut ticks_every : Int?
  mut height : Int?
}

///|
pub struct TimingDiagram {
  players : Array[TimingPlayer]
  clocks : Array[String]
  codes : Array[(String, TimeTick)]
  messages : Array[TimingMessage]
  highlights : Array[Highlight]
  time_marks : Array[TimeTick]
  mut now : TimeTick?
  mut last_player : String?
  mut time_axis : TimeAxisStrategy
  mut compact_by_default : Bool
  mut date_format : String?
  mut scale : (Int64, Int64)?
  style : @style.DocumentStyle
}

///|
pub fn TimingDiagram::player(
  self : TimingDiagram,
  code : String,
) -> TimingPlayer? {
  for player in self.players {
    if player.code == code {
      return Some(player)
    }
  }
  None
}

///|
pub fn TimingDiagram::clock(
  self : TimingDiagram,
  code : String,
) -> TimingPlayer? {
  guard self.clocks.contains(code) else { return None }
  self.player(code)
}

///|
/// Returns the time value bound to a `@time as :code` label.
pub fn TimingDiagram::code_value(
  self : TimingDiagram,
  code : String,
) -> TimeTick? {
  for item in self.codes {
    if item.0 == code {
      return Some(item.1)
    }
  }
  None
}

///|
pub fn TimingPlayer::is_state_player(self : TimingPlayer) -> Bool {
  match self.kind {
    Robust | Concise | Rectangle => true
    Binary | Clock | Analog => false
  }
}
