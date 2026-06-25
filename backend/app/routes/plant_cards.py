from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import datetime
from app.database import get_db
from app.models import PlantCard, HealthLog, User
from app.schemas import PlantCardResponse, PlantCardCreate, HealthLogResponse, HealthLogCreate

router = APIRouter(tags=["PlantCards"])

@router.get("/api/users/{user_id}/plantcards", response_model=List[PlantCardResponse])
def get_user_plant_cards(user_id: int, db: Session = Depends(get_db)):
    # Check if user exists, if not create a mock user so the app works instantly
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        user = User(user_id=user_id, name="Test User", email="test@greennest.com", mobile="1234567890")
        db.add(user)
        db.commit()
        db.refresh(user)
        
    return db.query(PlantCard).filter(PlantCard.user_id == user_id).all()

@router.post("/api/users/{user_id}/plantcards", response_model=PlantCardResponse)
def create_plant_card(user_id: int, payload: PlantCardCreate, db: Session = Depends(get_db)):
    card = PlantCard(
        user_id=user_id,
        nickname=payload.nickname,
        species=payload.species,
        photo_url=payload.photo_url,
        location=payload.location,
        light_exposure=payload.light_exposure,
        water_frequency=payload.water_frequency,
        fertilize_frequency=payload.fertilize_frequency
    )
    db.add(card)
    db.commit()
    db.refresh(card)
    
    # Automatically add an initialization log
    log = HealthLog(
        plant_card_id=card.plant_card_id,
        entry_type="Manual",
        diagnosis="Added to GreenNest Garden",
        confidence=100.0,
        photo_url=payload.photo_url
    )
    db.add(log)
    db.commit()
    db.refresh(card)
    return card

@router.get("/api/plantcards/{plant_card_id}", response_model=PlantCardResponse)
def get_plant_card_details(plant_card_id: int, db: Session = Depends(get_db)):
    card = db.query(PlantCard).filter(PlantCard.plant_card_id == plant_card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Plant Card not found")
    return card

@router.put("/api/plantcards/{plant_card_id}", response_model=PlantCardResponse)
def update_plant_card(plant_card_id: int, payload: PlantCardCreate, db: Session = Depends(get_db)):
    card = db.query(PlantCard).filter(PlantCard.plant_card_id == plant_card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Plant Card not found")
    
    card.nickname = payload.nickname
    card.species = payload.species
    if payload.photo_url:
        card.photo_url = payload.photo_url
    card.location = payload.location
    card.light_exposure = payload.light_exposure
    card.water_frequency = payload.water_frequency
    card.fertilize_frequency = payload.fertilize_frequency
    
    db.commit()
    db.refresh(card)
    return card

@router.delete("/api/plantcards/{plant_card_id}")
def delete_plant_card(plant_card_id: int, db: Session = Depends(get_db)):
    card = db.query(PlantCard).filter(PlantCard.plant_card_id == plant_card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Plant Card not found")
    db.delete(card)
    db.commit()
    return {"message": "Plant card deleted successfully"}

@router.post("/api/plantcards/{plant_card_id}/logs", response_model=HealthLogResponse)
def add_health_log(plant_card_id: int, payload: HealthLogCreate, db: Session = Depends(get_db)):
    card = db.query(PlantCard).filter(PlantCard.plant_card_id == plant_card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Plant Card not found")
        
    log = HealthLog(
        plant_card_id=plant_card_id,
        entry_type=payload.entry_type,
        diagnosis=payload.diagnosis,
        confidence=payload.confidence,
        photo_url=payload.photo_url
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log
