from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models import Order, OrderItem, Gift, Plant, User
from app.schemas import OrderCreate, OrderResponse, GiftCreate, GiftResponse

router = APIRouter(tags=["Orders & Gifting"])

@router.post("/api/orders", response_model=OrderResponse)
def place_order(payload: OrderCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == payload.user_id).first()
    if not user:
        # Create mock user
        user = User(user_id=payload.user_id, name="Test User", email="test@greennest.com", mobile="1234567890")
        db.add(user)
        db.commit()
        db.refresh(user)

    total = 0
    order_items = []
    
    for item in payload.items:
        plant = db.query(Plant).filter(Plant.plant_id == item.plant_id).first()
        if not plant:
            raise HTTPException(status_code=404, detail=f"Plant with ID {item.plant_id} not found")
        if plant.stock < item.quantity:
            raise HTTPException(status_code=400, detail=f"Insufficient stock for plant: {plant.name}")
            
        # Deduct stock
        plant.stock -= item.quantity
        subtotal = plant.price * item.quantity
        total += subtotal
        
        order_items.append(
            OrderItem(
                plant_id=item.plant_id,
                quantity=item.quantity,
                price=plant.price
            )
        )
        
    order = Order(
        user_id=payload.user_id,
        total_amount=total,
        status="Processing"
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    
    # Save order items
    for item in order_items:
        item.order_id = order.order_id
        db.add(item)
        
    db.commit()
    db.refresh(order)
    return order

@router.post("/api/gifts", response_model=GiftResponse)
def send_gift(payload: GiftCreate, db: Session = Depends(get_db)):
    # Verify sender user
    sender = db.query(User).filter(User.user_id == payload.sender_id).first()
    if not sender:
        sender = User(user_id=payload.sender_id, name="Test User", email="test@greennest.com", mobile="1234567890")
        db.add(sender)
        db.commit()
        db.refresh(sender)

    # Verify plant
    plant = db.query(Plant).filter(Plant.plant_id == payload.plant_id).first()
    if not plant:
        raise HTTPException(status_code=404, detail="Plant not found")
    if plant.stock < 1:
        raise HTTPException(status_code=400, detail="Plant out of stock")
        
    # Deduct stock
    plant.stock -= 1
    
    gift = Gift(
        sender_id=payload.sender_id,
        recipient_name=payload.recipient_name,
        recipient_mobile=payload.recipient_mobile,
        recipient_address=payload.recipient_address,
        plant_id=payload.plant_id,
        message=payload.message,
        delivery_date=payload.delivery_date,
        gift_wrap=payload.gift_wrap,
        status="Scheduled"
    )
    db.add(gift)
    db.commit()
    db.refresh(gift)
    return gift

@router.get("/api/users/{user_id}/orders", response_model=List[OrderResponse])
def get_user_orders(user_id: int, db: Session = Depends(get_db)):
    return db.query(Order).filter(Order.user_id == user_id).all()

@router.get("/api/users/{user_id}/gifts", response_model=List[GiftResponse])
def get_user_gifts(user_id: int, db: Session = Depends(get_db)):
    return db.query(Gift).filter(Gift.sender_id == user_id).all()

@router.get("/api/admin/orders", response_model=List[OrderResponse])
def get_all_orders(db: Session = Depends(get_db)):
    return db.query(Order).order_by(Order.order_date.desc()).all()

@router.get("/api/admin/gifts", response_model=List[GiftResponse])
def get_all_gifts(db: Session = Depends(get_db)):
    return db.query(Gift).order_by(Gift.delivery_date.desc()).all()
