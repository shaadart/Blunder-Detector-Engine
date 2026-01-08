from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .models import PositionRequest, GameRequest, AnalysisResponse, GameProfile
from .analyzer import MAEAnalyzer

app = FastAPI(title="MAE Chess Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

analyzer = MAEAnalyzer()

@app.get("/")
def health_check():
    return {"status": "MAE Backend is running"}

@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_position(request: PositionRequest):
    try:
        if len(request.fen.split()) < 4:
             raise HTTPException(status_code=400, detail="Invalid FEN")
        return await analyzer.analyze_fen(request.fen)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- NEW ENDPOINT ---
@app.post("/analyze/game", response_model=GameProfile)
async def analyze_game(request: GameRequest):
    """
    Analyzes a full PGN. Returns a GameProfile with Mastery Score and per-move analysis.
    """
    try:
        return await analyzer.analyze_game_pgn(request.pgn)
    except Exception as e:
        print(f"Game Analysis Error: {e}")
        raise HTTPException(status_code=500, detail=f"Game analysis failed: {str(e)}")