/// Fight Camp Phase Theme Modes
/// Dynamic theming based on fighter's current training phase
enum DfcThemeMode {
  /// Default blue/cyan theme
  classic,

  /// Pre-camp preparation - Sky blue
  baseCamp,

  /// Active training camp - Green intensity
  fightCamp,

  /// Final week before fight - Red/Orange urgency
  fightWeek,

  /// Fight day - Amber/Gold focus
  fightDay,

  /// Post-fight recovery - Purple calm
  recovery,
}
