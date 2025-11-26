# embed.py
# Run this ONCE on the server to create /data/index.faiss and /data/names.npy
import os, sys
from PIL import Image
import numpy as np
import torch
import open_clip
import faiss

DATA_DIR = "/data/master_images"
INDEX_PATH = "/data/index.faiss"
NAMES_PATH = "/data/names.npy"
MODEL_NAME = "ViT-B-32"
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
BATCH_SIZE = 16

def load_model():
    model, _, preprocess = open_clip.create_model_and_transforms(MODEL_NAME, pretrained="openai")
    model.to(DEVICE).eval()
    return model, preprocess

def iter_images(folder):
    for fname in sorted(os.listdir(folder)):
        if fname.lower().endswith((".jpg",".jpeg",".png",".webp")):
            yield fname, os.path.join(folder, fname)

def main():
    if not os.path.isdir(DATA_DIR):
        print("DATA_DIR not found:", DATA_DIR, file=sys.stderr); sys.exit(1)
    model, preprocess = load_model()
    names = []
    vecs = []
    files = list(iter_images(DATA_DIR))
    print(f"Found {len(files)} images. Embedding on {DEVICE} ...")
    for i in range(0, len(files), BATCH_SIZE):
        batch = files[i:i+BATCH_SIZE]
        imgs = []
        for fname, path in batch:
            try:
                img = Image.open(path).convert("RGB")
                imgs.append(preprocess(img).unsqueeze(0))
                names.append(fname)
            except Exception as e:
                print("Skipping", fname, "err:", e)
        if not imgs:
            continue
        x = torch.cat(imgs, dim=0).to(DEVICE)
        with torch.no_grad():
            emb = model.encode_image(x).cpu().numpy().astype("float32")
        norms = np.linalg.norm(emb, axis=1, keepdims=True)
        emb = emb / (norms + 1e-10)
        vecs.append(emb)
        print(f"Processed {min(i+len(batch), len(files))}/{len(files)}")
    if not vecs:
        print("No vectors produced.", file=sys.stderr); sys.exit(1)
    vectors = np.vstack(vecs)
    dim = vectors.shape[1]
    print("Total vectors:", vectors.shape)
    index = faiss.IndexFlatIP(dim)
    index.add(vectors)
    faiss.write_index(index, INDEX_PATH)
    np.save(NAMES_PATH, np.array(names))
    print("Wrote index:", INDEX_PATH)
    print("Wrote names:", NAMES_PATH)
    print("Done.")

if __name__ == "__main__":
    main()
