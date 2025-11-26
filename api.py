import os
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

DATA_DIR = "/data/master_images"
os.makedirs(DATA_DIR, exist_ok=True)

app = FastAPI(title="FT Image Search (dev)")

app.mount("/static", StaticFiles(directory=DATA_DIR), name="static")

@app.get("/health")
def health():
    try:
        files = [f for f in os.listdir(DATA_DIR) if f.lower().endswith((".jpg",".png",".jpeg",".webp"))]
    except Exception:
        files = []
    return {"status": "ok", "num_images": len(files)}

@app.post("/search")
async def search(file: UploadFile = File(...), top_k: int = 5):
    # placeholder
    try:
        filenames = [f for f in os.listdir(DATA_DIR) if f.lower().endswith((".jpg",".png",".jpeg",".webp"))]
    except Exception:
        filenames = []
    sample = filenames[:top_k]
    return JSONResponse({"results": [{"sku": fn.split('.')[0], "filename": fn, "image_url": f"/static/{fn}"} for fn in sample]})
