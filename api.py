# api.py (light placeholder with filename parsing)
import os
from fastapi import FastAPI, File, UploadFile, Query
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

DATA_DIR = "/data/master_images"
os.makedirs(DATA_DIR, exist_ok=True)

app = FastAPI(title="FT Image Search (dev)")
app.mount("/static", StaticFiles(directory=DATA_DIR), name="static")

def parse_filename_meta(filename: str):
    """
    Parse filename format:
    SKU - Description - Category - Theme.ext
    Returns dict with keys: sku, description, category, theme, name
    Tolerant for fewer parts.
    """
    base = os.path.splitext(filename)[0].strip()
    parts = [p.strip() for p in base.split(" - ")]
    sku = parts[0] if len(parts) >= 1 else ""
    description = parts[1] if len(parts) >= 2 else ""
    category = parts[2] if len(parts) >= 3 else ""
    theme = parts[3] if len(parts) >= 4 else ""
    return {
        "sku": sku,
        "description": description,
        "category": category,
        "theme": theme,
        "name": description or base
    }

@app.get("/health")
def health():
    try:
        files = [f for f in os.listdir(DATA_DIR) if f.lower().endswith((".jpg",".png",".jpeg",".webp"))]
    except Exception:
        files = []
    return {"status": "ok", "num_images": len(files)}

@app.post("/search")
async def search(file: UploadFile = File(...), top_k: int = Query(5, ge=1, le=20)):
    """
    Placeholder search (no embedding yet).
    Returns top_k files (first in sorted order) with parsed metadata.
    When index is ready, this endpoint will be replaced to return true visual matches.
    """
    try:
        filenames = sorted([f for f in os.listdir(DATA_DIR) if f.lower().endswith((".jpg",".png",".jpeg",".webp"))])
    except Exception:
        filenames = []
    sample = filenames[:top_k]
    results = []
    for fn in sample:
        meta = parse_filename_meta(fn)
        results.append({
            "sku": meta["sku"],
            "name": meta["name"],
            "description": meta["description"],
            "category": meta["category"],
            "theme": meta["theme"],
            "filename": fn,
            "image_url": f"/static/{fn}",
            "score": 0.0
        })
    return JSONResponse({"query_results": results})
