import GraniteAgents

/// The granite agent's place in Granite's roster: an app that links this package finds the `granite` agent by this
/// record, with nothing listed by hand.
@used @section("__DATA_CONST,__granite")
let graniteRecord: GraniteRoster.Record = { GraniteRoster.record(GraniteAppAgent.self) }
