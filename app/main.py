from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .models import PositionRequest, AnalysisResponse
from .analyzer import MAEAnalyzer

app = FastAPI(title="MAE Chess Backend")

# Allow Flutter frontend (Web/Android emulators) to connect
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
    """
    Takes a FEN string, runs Stockfish analysis, and returns 
    data structured for the MAE Simple UI components.
    """
    try:
        # Basic FEN validation check
        if len(request.fen.split()) < 4:
             raise HTTPException(status_code=400, detail="Invalid FEN string format")
             
        result = await analyzer.analyze_fen(request.fen)
        return result
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        print(f"Error during analysis: {e}")
        raise HTTPException(status_code=500, detail="Internal analysis error")