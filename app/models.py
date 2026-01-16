from pydantic import BaseModel
from typing import List, Optional, Dict

# 1. Individual Move Analysis
class MoveAnalysis(BaseModel):
    move_number: int
    move_uci: str
    label: str               # e.g., "Pragmatic Simplification", "Blunder"
    win_chance: float        # 0-100%
    delta: float             # Change in win chance (Regret)
    difficulty: int          # 0-100 (PDI)
    risk: int                # 0-100 (RVS)
    best_move: Optional[str] # The move Stockfish wanted (if different)
    eval_display: str        # e.g. "+1.50" or "#3"

# 2. Game Statistics
class GameStats(BaseModel):
    blunders: int
    avg_difficulty: int      # The average PDI of the game
    pushups: int             # Your accountability metric

# 3. The Full Response Object
class GameAnalysisResponse(BaseModel):
    players: Dict[str, str]  # {"user": "Shrad", "opponent": "Magnus"}
    result: str              # "1-0", "0-1", "1/2-1/2"
    stats: GameStats
    moves: List[MoveAnalysis]