# Use official Python image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y git && apt-get clean

# Copy project files
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose Fly.io port
EXPOSE 8080

# Start command
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8080"]
