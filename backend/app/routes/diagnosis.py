from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas import DiagnosisQuery, DiagnosisResponse
from app.engines.diagnosis import diagnose_plant

router = APIRouter(prefix="/api/diagnosis", tags=["Diagnosis"])

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
