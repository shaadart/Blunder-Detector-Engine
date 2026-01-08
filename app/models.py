from pydantic import BaseModel
from typing import List, Optional

# --- INPUT ---
class PositionRequest(BaseModel):
    fen: str

# --- OUTPUT COMPONENTS ---

# 1. The Eval Bar Data
class EvalBarData(BaseModel):
    score_cp: int  # Centipawn score (+150, -50, etc.)
    winning_chance: float # 0.0 to 1.0 (e.g., 0.65)
    is_volatile: bool # Determines if the bar should "glow" (High Risk)

# 3. Board Arrows Data (Simplified for MVP)
class SuggestionArrow(BaseModel):
    move_uci: str # e.g., "e2e4"
    type: str # "engine" (Cyan) or "practical" (Green)

# 4. Best Line & Explanation Data
class BestLineData(BaseModel):
    truncated_line: str # e.g., "1. Nf3 d5 2. g3"
    explanation: str # Natural language reason for the move

# --- MAIN API RESPONSE ---
class AnalysisResponse(BaseModel):
    fen: str
    eval_bar: EvalBarData
    arrows: List[SuggestionArrow]
    best_line: BestLineData