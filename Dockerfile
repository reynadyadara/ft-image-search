FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --upgrade pip
# install system deps for pillow/faiss
RUN apt-get update && apt-get install -y build-essential wget unzip libsndfile1 && rm -rf /var/lib/apt/lists/*

# install pip deps (torch + open_clip + faiss-cpu may be large)
RUN pip install -r requirements.txt

COPY . .
ENV DATA_DIR=/data
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8080"]
