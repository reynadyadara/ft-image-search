FROM python:3.10-slim

WORKDIR /app

# install git + build tools + libs needed for image/model packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git build-essential libgl1 libglib2.0-0 ffmpeg && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# note: at runtime render/fly will set PORT env; here default to 8080
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8080"]