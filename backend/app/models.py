import datetime
from sqlalchemy import Column, Integer, String, Numeric, Date, DateTime, Boolean, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    mobile = Column(String(20), nullable=False)
    address = Column(Text, nullable=True)
    password = Column(String(100), nullable=False, default="password")
    role = Column(String(50), nullable=False, default="User") # "Admin" or "User"
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    orders = relationship("Order", back_populates="user")
    gifts = relationship("Gift", back_populates="sender")
    plant_cards = relationship("PlantCard", back_populates="user")


class Plant(Base):
    __tablename__ = "plants"

    plant_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    category = Column(String(50), nullable=False)
    description = Column(Text, nullable=True)
    price = Column(Numeric(10, 2), nullable=False)
    stock = Column(Integer, default=0)
    sunlight = Column(String(50), nullable=True)
    water_frequency = Column(String(50), nullable=True)
    image_url = Column(String(255), nullable=True)
    
    # Recommendation metadata stored as JSON lists
    purpose = Column(JSON, default=[])      # e.g., ["Air Purification", "Decoration"]
    location = Column(JSON, default=[])     # e.g., ["Bedroom", "Living Room"]
    light = Column(JSON, default=[])        # e.g., ["Low", "Medium"]
    season = Column(JSON, default=[])       # e.g., ["Summer", "All Season"]
    maintenance = Column(String(50), default="Low") # "Low", "Medium", "High"
    gift_for = Column(JSON, default=[])     # e.g., ["Friend", "Mother"]
    occasion = Column(JSON, default=[])     # e.g., ["Birthday", "Anniversary"]


class Order(Base):
    __tablename__ = "orders"

    order_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    total_amount = Column(Numeric(10, 2), nullable=False)
    status = Column(String(50), default="Pending") # Pending, Processing, Shipped, Completed
    order_date = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="orders")
    items = relationship("OrderItem", back_populates="order")


class OrderItem(Base):
    __tablename__ = "order_items"

    order_item_id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=False)
    plant_id = Column(Integer, ForeignKey("plants.plant_id"), nullable=False)
    quantity = Column(Integer, nullable=False, default=1)
    price = Column(Numeric(10, 2), nullable=False)

    order = relationship("Order", back_populates="items")
    plant = relationship("Plant")


class Gift(Base):
    __tablename__ = "gifts"

    gift_id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    recipient_name = Column(String(100), nullable=False)
    recipient_mobile = Column(String(20), nullable=False)
    recipient_address = Column(Text, nullable=False)
    plant_id = Column(Integer, ForeignKey("plants.plant_id"), nullable=False)
    message = Column(Text, nullable=True)
    delivery_date = Column(Date, nullable=False)
    status = Column(String(50), default="Scheduled") # Scheduled, Dispatched, Delivered
    gift_wrap = Column(Boolean, default=False)

    sender = relationship("User", back_populates="gifts")
    plant = relationship("Plant")


class PlantCard(Base):
    __tablename__ = "plant_cards"

    plant_card_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    nickname = Column(String(100), nullable=False)
    species = Column(String(100), nullable=False)
    photo_url = Column(String(255), nullable=True)
    location = Column(String(100), nullable=True) # "Bedroom", "Balcony", etc.
    light_exposure = Column(String(100), nullable=True) # "Low", "Medium", "Bright Indirect", etc.
    date_added = Column(Date, default=datetime.date.today)
    water_frequency = Column(String(50), nullable=True) # e.g. "Every 3 days"
    fertilize_frequency = Column(String(50), nullable=True) # e.g. "Monthly"

    user = relationship("User", back_populates="plant_cards")
    health_logs = relationship("HealthLog", back_populates="plant_card", cascade="all, delete-orphan")


class HealthLog(Base):
    __tablename__ = "health_logs"

    log_id = Column(Integer, primary_key=True, index=True)
    plant_card_id = Column(Integer, ForeignKey("plant_cards.plant_card_id"), nullable=False)
    entry_type = Column(String(50), default="Manual") # Diagnosis, Watering, Fertilizing, Manual
    diagnosis = Column(String(100), nullable=True)
    confidence = Column(Numeric(5, 2), nullable=True) # e.g., 82.50
    photo_url = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    plant_card = relationship("PlantCard", back_populates="health_logs")


class DiagnosisRule(Base):
    __tablename__ = "diagnosis_rules"

    rule_id = Column(Integer, primary_key=True, index=True)
    cause = Column(String(100), nullable=False)
    symptom_tags = Column(JSON, default=[]) # e.g., ["yellow leaves", "soft stem"]
    context_tags = Column(JSON, default=[]) # e.g., ["frequent watering", "low light"]
    confidence_base = Column(Numeric(4, 2), default=0.60)
