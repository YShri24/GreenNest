from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
import os
from app.database import get_db
from app.schemas import DiagnosisQuery, DiagnosisResponse, ChatQuery
from app.engines.diagnosis import diagnose_plant
from app.engines.gemini import chat_with_gemini

router = APIRouter(prefix="/api/diagnosis", tags=["Diagnosis"])

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.abspath(os.path.join(BASE_DIR, "..", "..", "uploads"))

@router.post("", response_model=DiagnosisResponse)
def diagnose_plant_health(query: DiagnosisQuery, db: Session = Depends(get_db)):
    context = {
        "location": query.location,
        "light": query.light,
        "water_frequency": query.water_frequency
    }
    result = diagnose_plant(db, query.symptoms, context, query.plant_card_id)
    return result

@router.get("/symptoms", response_model=list[str])
def get_standard_symptoms():
    return [
        "yellow leaves",
        "soft stem",
        "mushy soil",
        "dry crispy leaves",
        "drooping",
        "leggy growth",
        "pale new leaves",
        "spots on leaves",
        "webbing on leaves",
        "holes in leaves",
        "pale veins",
        "slow growth"
    ]

@router.post("/chat")
def chat_bot_diagnosis(query: ChatQuery, db: Session = Depends(get_db)):
    # 1. Resolve local path of uploaded photo if photo_url is provided
    photo_path = None
    if query.photo_url:
        try:
            filename = query.photo_url.split("/uploads/")[-1]
            filename = filename.split("?")[0] # strip query params if any
            resolved_path = os.path.join(UPLOAD_DIR, filename)
            if os.path.exists(resolved_path):
                photo_path = resolved_path
            else:
                print(f"Uploaded file not found locally at: {resolved_path}")
        except Exception as e:
            print(f"Error parsing photo URL: {e}")

    # 2. Format history to list of dicts
    history_list = [{"sender": m.sender, "text": m.text} for m in query.history]

    # 3. Call Gemini chatbot
    try:
        result = chat_with_gemini(query.message, history_list, photo_path)
        return result
    except Exception as e:
        print(f"Gemini chatbot diagnosis failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Gemini API failure: {str(e)}"
        )

