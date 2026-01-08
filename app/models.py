from pydantic import BaseModel
from typing import List, Optional

# --- INPUT ---
class PositionRequest(BaseModel):
    fen: str

class GameRequest(BaseModel):
    pgn: str

# --- OUTPUT COMPONENTS ---
class EvalBarData(BaseModel):
    score_cp: int
    winning_chance: float
    is_volatile: bool

class SuggestionArrow(BaseModel):
    move_uci: str
    type: str

class BestLineData(BaseModel):
    truncated_line: str
    explanation: str

class TelemetryData(BaseModel):
    objective_score: float
    fragility_score: float
    chaos_score: float

class AnalysisResponse(BaseModel):
    fen: str
    move_number: int # New: Track move order
    eval_bar: EvalBarData
    telemetry: TelemetryData
    arrows: List[SuggestionArrow]
    best_line: BestLineData

# --- NEW: FULL GAME PROFILE ---
class GameProfile(BaseModel):
    mastery_score: int          # 0-100
    player_type: str         # "Risk Master", "Solid Defender", etc.
    avg_fragility: float
    avg_chaos: float
    blunder_count: int
    moves_analysis: List[AnalysisResponse]