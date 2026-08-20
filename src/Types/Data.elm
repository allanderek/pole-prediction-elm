module Types.Data exposing (Data(..))

import Types.FormulaE
import Types.FormulaOne
import Types.OverUnder


type Data
    = FormulaOneLeaderboard { season : Types.FormulaOne.Season }
    | FormulaOneEvents { season : Types.FormulaOne.Season }
    | FormulaOneEventSessions { eventId : Types.FormulaOne.EventId }
    | FormulaOneEntrants { sessionId : Types.FormulaOne.SessionId }
    | FormulaOneSessionLeaderboard { sessionId : Types.FormulaOne.SessionId }
    | FormulaOneSeasonLeaderboard { season : Types.FormulaOne.Season }
    | FormulaOneConcordantLeaderboard { season : Types.FormulaOne.Season }
    | FormulaOneConstructorStandings { season : Types.FormulaOne.Season }
    | FormulaOneDriverStandings { season : Types.FormulaOne.Season }
    | FormulaOneSeasonTeams { season : Types.FormulaOne.Season }
    | FormulaELeaderboard { season : Types.FormulaE.Season }
    | FormulaEEvents { season : Types.FormulaE.Season }
    | FormulaEEventEntrants { eventId : Types.FormulaE.EventId }
    | FormulaEEventLeaderboard { eventId : Types.FormulaE.EventId }
      -- Unlike the others this takes no spec, the endpoint returns every competition
      -- and its questions in one go.
    | OverUnderCompetitions
    | OverUnderLeaderboard { competitionId : Types.OverUnder.CompetitionId }
