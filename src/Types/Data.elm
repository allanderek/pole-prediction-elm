module Types.Data exposing (Data(..))

import Types.FormulaE
import Types.FormulaOne


type Data
    = FormulaOneLeaderboard { season : Types.FormulaOne.Season }
    | FormulaOneEvents { season : Types.FormulaOne.Season }
    | FormulaOneEventSessions { eventId : Types.FormulaOne.EventId }
    | FormulaOneEntrants { sessionId : Types.FormulaOne.SessionId }
    | FormulaOneSessionLeaderboard { sessionId : Types.FormulaOne.SessionId }
    | FormulaOneSeasonLeaderboard { season : Types.FormulaOne.Season }
    | FormulaOneConstructorStandings { season : Types.FormulaOne.Season }
    | FormulaOneDriverStandings { season : Types.FormulaOne.Season }
    | FormulaELeaderboard { season : Types.FormulaE.Season }
    | FormulaEEvents { season : Types.FormulaE.Season }
    | FormulaEEventEntrants { eventId : Types.FormulaE.EventId }
    | FormulaEEventLeaderboard { eventId : Types.FormulaE.EventId }
