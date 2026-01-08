import chess
import chess.engine
import chess.pgn
import math
import networkx as nx
import io
import statistics
from .models import (
    EvalBarData, SuggestionArrow, BestLineData, 
    AnalysisResponse, TelemetryData, GameProfile
)

# CONFIGURATION
STOCKFISH_PATH = "/usr/local/bin/stockfish"
ANALYSIS_DEPTH = 18 
MULTIPV = 5 
ENGINE_THREADS = 4
ENGINE_HASH = 2048

class MAEAnalyzer:
    def __init__(self):
        self.engine_path = STOCKFISH_PATH

    def _cp_to_win_chance(self, cp: int) -> float:
        return 1 / (1 + math.exp(-0.004 * cp))

    def _calculate_graph_fragility(self, board: chess.Board) -> float:
        G = nx.Graph()
        piece_map = board.piece_map()
        for square in piece_map:
            G.add_node(square)

        for square, piece in piece_map.items():
            attackers = board.attackers(not piece.color, square)
            for attacker_sq in attackers: G.add_edge(square, attacker_sq)
            defenders = board.attackers(piece.color, square)
            for defender_sq in defenders: G.add_edge(square, defender_sq)

        if G.number_of_nodes() < 2: return 0.0
        try:
            ac = nx.algebraic_connectivity(G, method='lanczos')
            return max(0.0, min(1.0, 1.0 - (ac / 4.0)))
        except:
            return 0.5

    async def analyze_fen(self, fen: str, depth=ANALYSIS_DEPTH, multipv=MULTIPV) -> AnalysisResponse:
        board = chess.Board(fen)
        return await self._analyze_board_instance(board, depth, multipv)

    async def _analyze_board_instance(self, board: chess.Board, depth, multipv) -> AnalysisResponse:
        transport, engine = await chess.engine.popen_uci(self.engine_path)
        await engine.configure({"Threads": ENGINE_THREADS, "Hash": ENGINE_HASH})

        try:
            fragility_score = self._calculate_graph_fragility(board)
            info = await engine.analyse(board, chess.engine.Limit(depth=depth), multipv=multipv)

            if not info: raise ValueError("Analysis failed")

            top_line = info[0]
            best_score_obj = top_line["score"].white()
            
            # 1. ROBUST SCORING (Handles Mate)
            if best_score_obj.is_mate():
                score_cp = 9999 if best_score_obj.mate() > 0 else -9999
            else:
                score_cp = best_score_obj.score()
                if score_cp is None: score_cp = 0 

            # 2. ROBUST VOLATILITY
            scores = [l["score"].white().score(mate_score=2000) for l in info]
            engine_confusion = False
            chaos_score = 0.0
            if len(scores) >= 3:
                gap = abs(scores[0] - scores[2])
                engine_confusion = gap < 35
                chaos_score = max(0.0, 1.0 - (gap / 50.0))

            is_volatile = engine_confusion or (fragility_score > 0.65)
            
            # 3. EXPLANATION
            explanation = "Balanced."
            if best_score_obj.is_mate():
                explanation = "Checkmate sequence found!"
            elif is_volatile: 
                explanation = "High complexity. Tactical precision required."
            elif abs(score_cp) > 150: 
                explanation = "Decisive advantage."

            # 4. ROBUST PV (The Fix for 'KeyError: pv')
            pv_moves = []
            arrows = []
            
            # Only try to get moves if the engine returned a variation
            if "pv" in top_line and len(top_line["pv"]) > 0:
                temp_board = board.copy()
                for move in top_line['pv'][:4]:
                    pv_moves.append(temp_board.san(move))
                    temp_board.push(move)
                
                # Add the arrow
                arrows.append(SuggestionArrow(move_uci=top_line["pv"][0].uci(), type="engine"))
            else:
                # If no PV (e.g. game over), just show empty string
                pv_moves = ["(Game Over)"]

            return AnalysisResponse(
                fen=board.fen(),
                move_number=board.fullmove_number,
                eval_bar=EvalBarData(
                    score_cp=score_cp,
                    winning_chance=self._cp_to_win_chance(score_cp),
                    is_volatile=is_volatile
                ),
                telemetry=TelemetryData(
                    objective_score=self._cp_to_win_chance(score_cp),
                    fragility_score=fragility_score,
                    chaos_score=chaos_score
                ),
                arrows=arrows,
                best_line=BestLineData(truncated_line=" ".join(pv_moves), explanation=explanation)
            )
        finally:
            await engine.quit()

    async def analyze_game_pgn(self, pgn_str: str) -> GameProfile:
        pgn = io.StringIO(pgn_str)
        game = chess.pgn.read_game(pgn)
        
        # If PGN is invalid/empty
        if game is None:
             raise ValueError("Could not parse PGN")

        board = game.board()
        
        analyzed_moves = []
        fragility_history = []
        chaos_history = []
        blunder_count = 0
        prev_score = 0

        for move in game.mainline_moves():
            board.push(move)
            # Analyze
            result = await self._analyze_board_instance(board, depth=16, multipv=3)
            analyzed_moves.append(result)
            
            # Stats
            fragility_history.append(result.telemetry.fragility_score)
            chaos_history.append(result.telemetry.chaos_score)
            
            current_score = result.eval_bar.score_cp
            # Simple Blunder Check
            if abs(current_score - prev_score) > 200: 
                blunder_count += 1
            prev_score = current_score

        avg_frag = statistics.mean(fragility_history) if fragility_history else 0
        avg_chaos = statistics.mean(chaos_history) if chaos_history else 0

        player_type = "Balanced Strategist"
        if avg_chaos > 0.4 and avg_frag > 0.5:
            player_type = "Risk Master"
        elif avg_frag < 0.3:
            player_type = "Solid Defender"
        elif blunder_count > 3:
            player_type = "Tactical Gambler"

        base_score = 100 - (blunder_count * 10)
        chaos_bonus = avg_chaos * 10
        mastery = int(max(0, min(100, base_score + chaos_bonus)))

        return GameProfile(
            mastery_score=mastery,
            player_type=player_type,
            avg_fragility=avg_frag,
            avg_chaos=avg_chaos,
            blunder_count=blunder_count,
            moves_analysis=analyzed_moves
        )