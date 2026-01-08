import chess
import chess.engine
import math
import networkx as nx
import numpy as np
from .models import EvalBarData, SuggestionArrow, BestLineData, AnalysisResponse, TelemetryData

# CONFIGURATION
STOCKFISH_PATH = "/usr/local/bin/stockfish"
ANALYSIS_DEPTH = 22
MULTIPV = 7
ENGINE_THREADS = 4
ENGINE_HASH = 2048

class MAEAnalyzer:
    def __init__(self):
        self.engine_path = STOCKFISH_PATH

    def _cp_to_win_chance(self, cp: int) -> float:
        return 1 / (1 + math.exp(-0.004 * cp))

    def _calculate_graph_fragility(self, board: chess.Board) -> float:
        """
        Builds an Interaction Graph of the board.
        Returns a 'Fragility Score' (0.0 to 1.0).
        High Score = High Fragility (Low Algebraic Connectivity).
        """
        G = nx.Graph()
        
        # 1. Add Nodes (Pieces)
        piece_map = board.piece_map()
        for square in piece_map:
            G.add_node(square)

        # 2. Add Edges (Attacks and Defenses)
        for square, piece in piece_map.items():
            # Incoming tension
            attackers = board.attackers(not piece.color, square)
            for attacker_sq in attackers:
                G.add_edge(square, attacker_sq)
            
            # Structural integrity
            defenders = board.attackers(piece.color, square)
            for defender_sq in defenders:
                G.add_edge(square, defender_sq)

        # 3. Calculate Algebraic Connectivity
        if G.number_of_nodes() < 2:
            return 0.0

        try:
            algebraic_connectivity = nx.algebraic_connectivity(G, method='lanczos')
            # Normalize: Low Connectivity = High Fragility
            fragility = max(0.0, 1.0 - (algebraic_connectivity / 4.0))
            return min(1.0, fragility)
        except Exception:
            return 0.5

    async def analyze_fen(self, fen: str) -> AnalysisResponse:
        board = chess.Board(fen)
        
        transport, engine = await chess.engine.popen_uci(self.engine_path)
        await engine.configure({
            "Threads": ENGINE_THREADS,
            "Hash": ENGINE_HASH, 
            "Skill Level": 20
        })

        try:
            # --- 1. Graph Analysis ---
            fragility_score = self._calculate_graph_fragility(board)

            # --- 2. Engine Analysis ---
            info = await engine.analyse(
                board, 
                chess.engine.Limit(depth=ANALYSIS_DEPTH), 
                multipv=MULTIPV
            )

            if not info: raise ValueError("Analysis failed")

            top_line = info[0]
            best_score_obj = top_line["score"].white()
            
            if best_score_obj.is_mate():
                score_cp = 9999 if best_score_obj.mate() > 0 else -9999
            else:
                score_cp = best_score_obj.score()

            # --- 3. Hybrid Volatility Logic ---
            scores = []
            for line in info:
                s = line["score"].white()
                scores.append(s.score() if not s.is_mate() else (2000 if s.mate() > 0 else -2000))
            
            engine_confusion = False
            if len(scores) >= 3:
                gap_1_to_3 = abs(scores[0] - scores[2])
                if gap_1_to_3 < 35: engine_confusion = True

            is_volatile = engine_confusion or (fragility_score > 0.65)

            # --- 4. Explanation Generation ---
            pv_moves = []
            temp_board = board.copy()
            for move in top_line['pv'][:5]:
                pv_moves.append(temp_board.san(move))
                temp_board.push(move)
            
            explanation = "Position is solid."
            if is_volatile:
                if engine_confusion:
                    explanation = "Tactical chaos. Multiple moves have similar evaluations."
                elif fragility_score > 0.65:
                    explanation = f"High Structural Fragility ({fragility_score:.2f}). One mistake could collapse the defense."
            elif abs(score_cp) > 100:
                explanation = "One side has a decisive material or positional advantage."

            # --- 5. CALCULATE CHAOS SCORE (This was missing) ---
            if len(scores) >= 3:
                gap_val = abs(scores[0] - scores[2])
                # Normalize: 0 gap = 1.0 chaos, 50+ gap = 0.0 chaos
                chaos_score = max(0.0, 1.0 - (gap_val / 50.0))
            else:
                chaos_score = 0.0

            return AnalysisResponse(
                fen=fen,
                eval_bar=EvalBarData(
                    score_cp=score_cp,
                    winning_chance=self._cp_to_win_chance(score_cp) if abs(score_cp) < 9000 else (1.0 if score_cp > 0 else 0.0),
                    is_volatile=is_volatile
                ),
                telemetry=TelemetryData(
                    objective_score=self._cp_to_win_chance(score_cp),
                    fragility_score=fragility_score,
                    chaos_score=chaos_score # Now this variable exists!
                ),
                arrows=[SuggestionArrow(move_uci=top_line["pv"][0].uci(), type="engine")],
                best_line=BestLineData(
                    truncated_line=" ".join(pv_moves) + "...",
                    explanation=explanation
                )
            )

        finally:
            await engine.quit()