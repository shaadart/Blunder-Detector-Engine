from fastapi import FastAPI, HTTPException, Body, Query
from fastapi.middleware.cors import CORSMiddleware
from .models import GameAnalysisResponse
from .analyzer import analyze_pgn 

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def home():
    return {"message": "MAE Chess Engine is Running"}

@app.post("/analyze-game", response_model=GameAnalysisResponse)
def analyze_game(
    # 1. Username is now a Query Parameter (?username=Shrad)
    username: str = Query(..., description="The chess username to analyze perspective for"),
    
    # 2. PGN is now the Raw Body (Text)
    pgn: str = Body(..., media_type="text/plain", description="Raw PGN text content")
):
    """
    Analyzes a full game PGN.
    
    Input: Raw Text Body (The PGN string)
    Query Param: ?username=YourName
    """
    try:
        # Pass the raw PGN string directly to the analyzer
        analysis_result = analyze_pgn(pgn, username)
        return analysis_result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal Engine Error")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)