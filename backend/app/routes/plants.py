from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.models import Plant
from app.schemas import PlantResponse, RecommendationQuery, RecommendationResponseItem, PlantCreate, PlantResponse
from app.engines.recommendation import get_recommendations

router = APIRouter(prefix="/api/plants", tags=["Plants"])

@router.post("", response_model=PlantResponse)
def add_new_plant(payload: PlantCreate, db: Session = Depends(get_db)):
    plant = Plant(
        name=payload.name,
        category=payload.category,
        description=payload.description,
        price=payload.price,
        stock=payload.stock,
        sunlight=payload.sunlight,
        water_frequency=payload.water_frequency,
        image_url=payload.image_url,
        purpose=payload.purpose,
        location=payload.location,
        light=payload.light,
        season=payload.season,
        maintenance=payload.maintenance,
        gift_for=payload.gift_for,
        occasion=payload.occasion
    )
    db.add(plant)
    db.commit()
    db.refresh(plant)
    return plant

@router.get("", response_model=List[PlantResponse])
def get_all_plants(category: Optional[str] = None, search: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(Plant)
    if category:
        query = query.filter(Plant.category.ilike(category))
    if search:
        query = query.filter(Plant.name.ilike(f"%{search}%"))
    return query.all()

@router.get("/{plant_id}", response_model=PlantResponse)
def get_plant_details(plant_id: int, db: Session = Depends(get_db)):
    plant = db.query(Plant).filter(Plant.plant_id == plant_id).first()
    if not plant:
        raise HTTPException(status_code=404, detail="Plant not found")
    return plant

@router.post("/recommend", response_model=List[RecommendationResponseItem])
def recommend_plants(query: RecommendationQuery, db: Session = Depends(get_db)):
    answers = query.dict()
    results = get_recommendations(db, answers)
    
    response = []
    for item in results:
        # Construct plant schema
        plant_data = PlantResponse.from_orm(item["plant"])
        response.append(
            RecommendationResponseItem(
                plant=plant_data,
                score=item["score"],
                reasons=item["reasons"]
            )
        )
    return response

@router.put("/{plant_id}", response_model=PlantResponse)
def update_plant(plant_id: int, payload: PlantCreate, db: Session = Depends(get_db)):
    plant = db.query(Plant).filter(Plant.plant_id == plant_id).first()
    if not plant:
        raise HTTPException(status_code=404, detail="Plant not found")
        
    plant.name = payload.name
    plant.category = payload.category
    plant.description = payload.description
    plant.price = payload.price
    plant.stock = payload.stock
    plant.sunlight = payload.sunlight
    plant.water_frequency = payload.water_frequency
    plant.image_url = payload.image_url
    plant.purpose = payload.purpose
    plant.location = payload.location
    plant.light = payload.light
    plant.season = payload.season
    plant.maintenance = payload.maintenance
    plant.gift_for = payload.gift_for
    plant.occasion = payload.occasion
    
    db.commit()
    db.refresh(plant)
    return plant

@router.delete("/{plant_id}")
def delete_plant(plant_id: int, db: Session = Depends(get_db)):
    plant = db.query(Plant).filter(Plant.plant_id == plant_id).first()
    if not plant:
        raise HTTPException(status_code=404, detail="Plant not found")
        
    db.delete(plant)
    db.commit()
    return {"message": f"Plant '{plant.name}' successfully deleted"}
