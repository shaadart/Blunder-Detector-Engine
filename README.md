<img width="1172" height="848" alt="image" src="https://github.com/user-attachments/assets/87219ed9-7d31-4b30-aea0-f0eae81e30e6" />


<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Stockfish-000000?style=for-the-badge&logo=lichess&logoColor=white" alt="Stockfish"/>
  <img src="https://img.shields.io/badge/v1.0-Windows%2095-008080?style=for-the-badge" alt="Version"/>
</p>

<h1 align="center">Blunder Detector</h1>

<p align="center">
  <em>Move Analysis Engine</em><br/>
  <strong>Learn from your mistakes. Play better chess.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-v1.0-brightgreen?style=flat-square" alt="Status"/>
</p>

---

## What is this?

A chess game analyzer with **Stockfish 16** under the hood and a retro **Windows 95** UI because... why not?

Paste your PGN. Get instant feedback on every blunder, mistake, and inaccuracy. Become a better player.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Deep Analysis** | Stockfish 16 evaluates every move |
| **Move Classification** | Blunders • Mistakes • Inaccuracies |
| **Chess Tutor** | Real-time explanations with best move suggestions |
| **Full Move Table** | All moves with piece symbols (♔♕♖♗♘♙) |
| **Retro Vibes** | Windows 95 aesthetic, because nostalgia |

---

##  Setup

### Prerequisites
- Flutter SDK 3.10+
- Docker (for Stockfish backend)

### 1. Start the Engine

```bash
docker run -p 8000:8000 stockfish-api
```

### 2. Launch the UI

```bash
cd mae_chess_ui
flutter run -d chrome --web-port=8080
```

### 3. Analyze

1. **File → Load PGN**
2. Paste your game
3. Use **← →** arrows to navigate
4. Learn from your mistakes

---

## Controls

| Key | Action |
|-----|--------|
| `←` | Previous move |
| `→` | Next move |
| `Home` | First move |
| `End` | Last move |

---

## Architecture

```
mae_chess_ui/          Flutter Web App
     │
     │  HTTP/REST
     ▼
stockfish-api          Docker Container
     │
     │  UCI Protocol
     ▼
Stockfish 16           Chess Engine
```

---

##  Aesthetics

<img width="677" height="490" alt="image" src="https://github.com/user-attachments/assets/97c109b8-871c-4a74-8158-99aeb24243f7" />


> *"The Windows 95 UI makes losing at chess feel nostalgic."*

- Chess.com-style board colors
- Color-coded moves (🔴 blunder • 🟡 mistake • 🟠 inaccuracy)
- Typewriter effect tutor console
- Classic beveled buttons and panels

---

## Tech Stack

- **Frontend:** Flutter Web
- **Engine:** Stockfish 16
- **Backend:** FastAPI + Docker
- **Chess Logic:** `chess` package for Dart

---

<p align="center">
  <em>Built with ☕ and questionable UI decisions</em>
</p>
