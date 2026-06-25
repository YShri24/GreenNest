import os
import shutil
import uuid
from fastapi import FastAPI, UploadFile, File
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.routes import plants, diagnosis, plant_cards, orders, auth

# Auto-create SQLite database tables on startup
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="GreenNest Backend API",
    description="Backend service for rule-based plant recommendations, e-commerce catalog, checkouts, and plant health diagnosis.",
    version="1.0.0"
)

# Enable CORS for frontend connectivity (Flutter/Web apps)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create uploads directory if not exists
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Mount static folder
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Register routers
app.include_router(auth.router)
app.include_router(plants.router)
app.include_router(diagnosis.router)
app.include_router(plant_cards.router)
app.include_router(orders.router)

@app.post("/api/upload")
def upload_file(file: UploadFile = File(...)):
    # Generate unique filename to avoid collisions
    file_extension = os.path.splitext(file.filename)[1] if file.filename else ".jpg"
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"url": f"/uploads/{unique_filename}"}

@app.get("/")
def read_root():
    return {
        "message": "Welcome to GreenNest API Server!",
        "documentation": "/docs"
    }
