from pydantic import BaseModel
from typing import List, Optional

# --- INPUT ---
class PositionRequest(BaseModel):
    fen: str

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

# NEW: Raw Data for the Radar Chart
class TelemetryData(BaseModel):
    objective_score: float  # 0.0 - 1.0 (Win Probability)
    fragility_score: float  # 0.0 - 1.0 (Graph Connectivity)
    chaos_score: float      # 0.0 - 1.0 (Engine Confusion/Gap)

class AnalysisResponse(BaseModel):
    fen: str
    eval_bar: EvalBarData
    telemetry: TelemetryData  # <--- Added this
    arrows: List[SuggestionArrow]
    best_line: BestLineData