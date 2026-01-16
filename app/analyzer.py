import chess
import chess.pgn
import io
import numpy as np
import networkx as nx
import math
from stockfish import Stockfish

# ─────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────
STOCKFISH_PATH = "/usr/local/bin/stockfish" 

stockfish = Stockfish(
    path=STOCKFISH_PATH,
    depth=18,
    parameters={
        "Threads": 4,
        "Hash": 1024,
        "MultiPV": 3,
        "Skill Level": 20,
    },
)

_CACHE = {}

# ─────────────────────────────────────────────────────────────
# HELPER FUNCTIONS
# ─────────────────────────────────────────────────────────────

def parse_eval(eval_dict: dict) -> int:
    typ = eval_dict["type"]
    val = eval_dict["value"]
    if typ == "mate":
        return 10000 * val if val > 0 else -10000 * abs(val) 
    return val

def get_cp_mate(top_move: dict) -> int:
    mate = top_move.get("Mate")
    if mate is not None:
        return 10000 * mate if mate > 0 else -10000 * abs(mate)
    return top_move.get("Centipawn", 0)

def format_eval(val: int) -> str:
    if abs(val) > 9000:
        mate_in = math.ceil((10000 - abs(val)) / 2) if val > 0 else -math.ceil((10000 - abs(val)) / 2)
        return f"#{mate_in}"
    return f"{val / 100:+.2f}"

def cp_to_winprob(cp: float) -> float:
    cp = max(-1000, min(1000, cp)) 
    return 100 / (1 + math.exp(-0.00368208 * cp))

def normalize(cp: int, is_white: bool) -> int:
    return cp if is_white else -cp

# ─────────────────────────────────────────────────────────────
# AXIS 2: FRAGILITY (Complexity)
# ─────────────────────────────────────────────────────────────
def compute_fragility(board: chess.Board) -> float:
    if board.is_game_over(): return 0.0
    G = nx.Graph()
    pieces = board.piece_map()
    white_sq = [sq for sq, p in pieces.items() if p.color == chess.WHITE]
    black_sq = [sq for sq, p in pieces.items() if p.color == chess.BLACK]
    if not white_sq or not black_sq: return 0.0
    
    G.add_nodes_from(white_sq, bipartite=0)
    G.add_nodes_from(black_sq, bipartite=1)

    for sq in pieces:
        attacks = board.attacks(sq)
        attacker_color = board.color_at(sq)
        for target in attacks:
            if board.piece_at(target) and board.color_at(target) != attacker_color:
                G.add_edge(sq, target)

    if G.number_of_edges() == 0: return 0.0
    degrees = dict(G.degree())
    total_degree = sum(degrees.values())
    if total_degree == 0: return 0.0
    return min(1.0, (total_degree / G.number_of_nodes()) / 4.0)

# ─────────────────────────────────────────────────────────────
# CORE ANALYSIS
# ─────────────────────────────────────────────────────────────
def compute_position_metrics(board: chess.Board, player_is_white: bool) -> dict:
    fen = board.fen()
    if fen in _CACHE: return _CACHE[fen]

    stockfish.set_fen_position(fen)
    
    # Static Eval
    current_eval_dict = stockfish.get_evaluation()
    current_eval_raw = parse_eval(current_eval_dict)
    current_eval_norm = normalize(current_eval_raw, player_is_white)

    # MultiPV (Top Lines)
    top_moves = stockfish.get_top_moves(3)
    if not top_moves: return {} 

    # Extract Metrics
    after_evals_raw = [get_cp_mate(tm) for tm in top_moves]
    after_evals_norm = [normalize(e, player_is_white) for e in after_evals_raw]
    
    best_eval = after_evals_norm[0]
    best_move_uci = top_moves[0]["Move"]

    # ---------------------------------------------------------
    # FEATURE 3: Generate the "Best Line" (SAN variation)
    # ---------------------------------------------------------
    pv_uci = top_moves[0].get("PV", [])
    pv_san = []
    temp_board = board.copy()
    for m_uci in pv_uci[:6]: # Show next 6 moves
        try:
            m = chess.Move.from_uci(m_uci)
            pv_san.append(temp_board.san(m))
            temp_board.push(m)
        except:
            break
    best_line_str = " ".join(pv_san)
    # ---------------------------------------------------------

    variance = np.var(after_evals_norm) if len(after_evals_norm) > 1 else 0
    fragility = compute_fragility(board)
    
    legal_moves = list(board.legal_moves)
    complexity_penalty = math.log2(len(legal_moves)) / 10.0 if legal_moves else 0

    pdi = 0.4 * (math.sqrt(variance) / 500) + 0.4 * fragility + 0.2 * complexity_penalty
    rvs = 0.5 * (math.sqrt(variance) / 300) + 0.3 * fragility + 0.2 * complexity_penalty # Simpler RVS approximation

    metrics = {
        "eval_raw": current_eval_norm,
        "best_eval_raw": best_eval,
        "best_move": best_move_uci,
        "best_line": best_line_str, # <--- NEW FIELD
        "curr_winprob": cp_to_winprob(current_eval_norm),
        "best_winprob": cp_to_winprob(best_eval),
        "pdi": np.clip(pdi, 0.0, 1.0),
        "rvs": np.clip(rvs, 0.0, 1.0),
        "eval_str": format_eval(current_eval_raw),
    }
    
    _CACHE[fen] = metrics
    return metrics

def detect_intent(pre_board: chess.Board, move: chess.Move, post_board: chess.Board, pre_eval: int) -> str:
    captured = pre_board.piece_at(move.to_square) is not None
    check = post_board.is_check()
    pre_pieces = len(pre_board.piece_map())
    post_pieces = len(post_board.piece_map())
    
    if pre_eval > 300 and post_pieces < pre_pieces: return "simplification"
    if captured and abs(pre_eval) < 200: return "gambit"
    if pre_eval < -300 and (check or captured): return "swindle"
    return "standard"

def classify_move(delta_winprob: float, rvs: float, intent: str, is_opening: bool) -> str:
    regret = -delta_winprob 
    
    if is_opening:
        if regret > 25: return "Opening Blunder"
        if regret > 10: return "Dubious Opening"
        return "Book/Standard"

    if regret > 20:
        if intent == "swindle": return "Desperate Complication"
        return "Blunder (Outcome Changed)"
        
    if regret > 10:
        if intent == "simplification": return "Pragmatic Simplification"
        if rvs > 0.7: return "Speculative / Risky"
        return "Mistake"
        
    if regret > 3:
        if intent == "simplification": return "Good Simplification"
        return "Inaccuracy"

    return "Best / Excellent"

# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────
def analyze_pgn(pgn_str: str, username: str = None) -> dict:
    game = chess.pgn.read_game(io.StringIO(pgn_str))
    if not game: raise ValueError("Invalid PGN")

    headers = game.headers
    user = username.strip().lower() if username else "hero"
    white = headers.get("White", "").lower()
    black = headers.get("Black", "").lower()
    
    if user in white:
        player_is_white = True
        player_name = headers.get("White")
        opp_name = headers.get("Black")
    elif user in black:
        player_is_white = False
        player_name = headers.get("Black")
        opp_name = headers.get("White")
    else:
        player_is_white = True 
        player_name = headers.get("White")
        opp_name = headers.get("Black")

    board = game.board()
    analysis_details = []
    blunder_count = 0
    sum_difficulty = 0
    move_count = 0

    for ply, move in enumerate(game.mainline_moves()):
        is_player_move = ((ply % 2 == 0 and player_is_white) or (ply % 2 == 1 and not player_is_white))
        
        if not is_player_move:
            board.push(move)
            continue
            
        pre_metrics = compute_position_metrics(board, player_is_white)
        pre_board = board.copy()
        board.push(move)
        post_metrics = compute_position_metrics(board, player_is_white)
        
        delta_winprob = post_metrics["curr_winprob"] - pre_metrics["best_winprob"]
        intent = detect_intent(pre_board, move, board, pre_metrics["best_eval_raw"])
        is_opening = (ply // 2) < 6
        
        label = classify_move(delta_winprob, pre_metrics["rvs"], intent, is_opening)
        
        if "Blunder" in label or "Mistake" in label:
            blunder_count += 1

        # ---------------------------------------------------------
        # FEATURE 1 & 2: Better Best Move Logic
        # ---------------------------------------------------------
        
        # 1. Always show the engine's move initially
        engine_best = pre_metrics["best_move"]
        
        # 2. If you played Excellent, don't confuse user with an alternative
        if "Best" in label or "Excellent" in label or "Standard" in label:
             # Just show what they played, so UI doesn't say "Best move was X" when they played Y
            engine_best = move.uci()
        
        # 3. If it IS a mistake, ensure we actually have the suggestion
        elif engine_best is None:
             # Should practically never happen with MultiPV=3
             engine_best = "Unknown"

        analysis_details.append({
            "move_number": (ply // 2) + 1,
            "move_uci": move.uci(),
            "label": label,
            "win_chance": round(post_metrics["curr_winprob"], 1),
            "delta": round(delta_winprob, 1),
            "difficulty": round(pre_metrics["pdi"] * 100),
            "risk": round(pre_metrics["rvs"] * 100),
            "best_move": engine_best,           # Now reliable
            "best_line": pre_metrics["best_line"], # The Variation (e.g. "Nf3 e5 d4")
            "eval_display": post_metrics["eval_str"]
        })
        
        move_count += 1
        sum_difficulty += pre_metrics["pdi"]

    avg_difficulty = int((sum_difficulty / move_count) * 100) if move_count else 0
    
    return {
        "players": {"user": player_name, "opponent": opp_name},
        "result": headers.get("Result", "*"),
        "stats": {
            "blunders": blunder_count,
            "avg_difficulty": avg_difficulty,
            "pushups": blunder_count * 10 
        },
        "moves": analysis_details
    }