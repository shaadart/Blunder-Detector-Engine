# Use an official lightweight Python image
FROM python:3.10-slim

# Set working directory inside the container
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*



COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# COPY STOCKFISH TO /usr/local/bin/stockfish
# Ensure the file 'stockfish_16_linux' exists in your project folder
COPY stockfish_16_linux /usr/local/bin/stockfish
RUN chmod +x /usr/local/bin/stockfish

COPY ./app ./app

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]