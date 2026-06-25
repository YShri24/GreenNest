from pydantic import BaseModel, Field
from typing import List, Optional
from decimal import Decimal
import datetime

# --- User / Auth Schemas ---
class UserLogin(BaseModel):
    email: str
    password: str

class UserSignup(BaseModel):
    name: str
    email: str
    mobile: str
    password: str
    address: Optional[str] = None

class UserResponse(BaseModel):
    user_id: int
    name: str
    email: str
    mobile: str
    address: Optional[str] = None
    role: str
    created_at: datetime.datetime

    class Config:
        from_attributes = True

# --- Plant Schemas ---
class PlantResponse(BaseModel):
    plant_id: int
    name: str
    category: str
    description: Optional[str] = None
    price: Decimal
    stock: int
    sunlight: Optional[str] = None
    water_frequency: Optional[str] = None
    image_url: Optional[str] = None
    purpose: List[str] = []
    location: List[str] = []
    light: List[str] = []
    season: List[str] = []
    maintenance: str
    gift_for: List[str] = []
    occasion: List[str] = []

    class Config:
        from_attributes = True

class PlantCreate(BaseModel):
    name: str
    category: str
    description: Optional[str] = None
    price: Decimal
    stock: int
    sunlight: Optional[str] = None
    water_frequency: Optional[str] = None
    image_url: Optional[str] = None
    purpose: List[str] = []
    location: List[str] = []
    light: List[str] = []
    season: List[str] = []
    maintenance: str = "Low"
    gift_for: List[str] = []
    occasion: List[str] = []

# --- Recommendation Schemas ---
class RecommendationQuery(BaseModel):
    flow_type: str = "Personal" # "Personal" or "Gift"
    purpose: Optional[str] = None
    location: Optional[str] = None
    light: Optional[str] = None
    season: Optional[str] = None
    maintenance: Optional[str] = None
    gift_for: Optional[str] = None
    occasion: Optional[str] = None

class RecommendationResponseItem(BaseModel):
    plant: PlantResponse
    score: int
    reasons: List[str]

# --- Diagnosis Schemas ---
class DiagnosisQuery(BaseModel):
    symptoms: List[str]
    location: Optional[str] = None
    light: Optional[str] = None
    water_frequency: Optional[str] = None
    plant_card_id: Optional[int] = None

class DiagnosisResultItem(BaseModel):
    cause: str
    score: int
    confidence: float
    matches: List[str]
    steps: List[str]

class DiagnosisResponse(BaseModel):
    primary: DiagnosisResultItem
    alternates: List[DiagnosisResultItem]
    history_used: bool

# --- HealthLog Schemas ---
class HealthLogCreate(BaseModel):
    entry_type: str = "Manual" # "Diagnosis", "Watering", "Fertilizing", "Manual"
    diagnosis: Optional[str] = None
    confidence: Optional[float] = None
    photo_url: Optional[str] = None

class HealthLogResponse(BaseModel):
    log_id: int
    plant_card_id: int
    entry_type: str
    diagnosis: Optional[str] = None
    confidence: Optional[float] = None
    photo_url: Optional[str] = None
    created_at: datetime.datetime

    class Config:
        from_attributes = True

# --- PlantCard Schemas ---
class PlantCardCreate(BaseModel):
    nickname: str
    species: str
    photo_url: Optional[str] = None
    location: Optional[str] = None
    light_exposure: Optional[str] = None
    water_frequency: Optional[str] = None
    fertilize_frequency: Optional[str] = None

class PlantCardResponse(BaseModel):
    plant_card_id: int
    user_id: int
    nickname: str
    species: str
    photo_url: Optional[str] = None
    location: Optional[str] = None
    light_exposure: Optional[str] = None
    date_added: datetime.date
    water_frequency: Optional[str] = None
    fertilize_frequency: Optional[str] = None
    health_logs: List[HealthLogResponse] = []

    class Config:
        from_attributes = True

# --- Order & Gift Schemas ---
class OrderItemCreate(BaseModel):
    plant_id: int
    quantity: int = 1

class OrderCreate(BaseModel):
    user_id: int
    items: List[OrderItemCreate]

class OrderItemResponse(BaseModel):
    order_item_id: int
    plant_id: int
    quantity: int
    price: Decimal
    plant: PlantResponse

    class Config:
        from_attributes = True

class OrderResponse(BaseModel):
    order_id: int
    user_id: int
    total_amount: Decimal
    status: str
    order_date: datetime.datetime
    items: List[OrderItemResponse] = []

    class Config:
        from_attributes = True

class GiftCreate(BaseModel):
    sender_id: int
    recipient_name: str
    recipient_mobile: str
    recipient_address: str
    plant_id: int
    message: Optional[str] = None
    delivery_date: datetime.date
    gift_wrap: bool = False

class GiftResponse(BaseModel):
    gift_id: int
    sender_id: int
    recipient_name: str
    recipient_mobile: str
    recipient_address: str
    plant_id: int
    message: Optional[str] = None
    delivery_date: datetime.date
    status: str
    gift_wrap: bool
    plant: PlantResponse

    class Config:
        from_attributes = True
