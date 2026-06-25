from sqlalchemy.orm import Session
from app.models import Plant

def get_recommendations(db: Session, answers: dict) -> list:
    """
    Ranks plants based on user answers using the scoring weights:
    - Purpose: +5
    - Occasion: +5
    - Gift For: +5
    - Location: +3
    - Light: +3
    - Season: +2
    - Maintenance: +2
    """
    flow_type = answers.get("flow_type", "Personal")
    user_purpose = answers.get("purpose")
    user_location = answers.get("location")
    user_light = answers.get("light")
    user_season = answers.get("season")
    user_maintenance = answers.get("maintenance")
    user_gift_for = answers.get("gift_for")
    user_occasion = answers.get("occasion")

    # Fetch all plants from database
    plants = db.query(Plant).all()
    scored_plants = []

    for plant in plants:
        score = 0
        reasons = []

        # 1. Purpose (Weight: +5)
        if user_purpose and plant.purpose:
            if user_purpose in plant.purpose:
                score += 5
                reasons.append(f"Ideal for {user_purpose}")

        # 2. Location (Weight: +3)
        if user_location and plant.location:
            if user_location in plant.location:
                score += 3
                reasons.append(f"Suitable for the {user_location}")

        # 3. Light (Weight: +3)
        if user_light and plant.light:
            # Handle minor naming discrepancies (e.g. Low vs Low Light)
            plant_light_tags = [t.lower() for t in plant.light]
            cleaned_user_light = user_light.lower().replace(" light", "")
            matched = False
            for tag in plant_light_tags:
                if cleaned_user_light in tag or tag in cleaned_user_light:
                    matched = True
                    break
            if matched:
                score += 3
                reasons.append("Matches your available light level")

        # 4. Season (Weight: +2)
        if user_season and plant.season:
            if user_season in plant.season or "All" in plant.season or "All Season" in plant.season:
                score += 2
                reasons.append("Thrives in current season")

        # 5. Maintenance (Weight: +2)
        if user_maintenance and plant.maintenance:
            if user_maintenance.lower() == plant.maintenance.lower():
                score += 2
                reasons.append(f"Requires {user_maintenance.lower()} maintenance care")

        # 6. Gift For (Weight: +5 - Gift flow only)
        if flow_type == "Gift" and user_gift_for and plant.gift_for:
            if user_gift_for in plant.gift_for:
                score += 5
                reasons.append(f"Perfect gift for a {user_gift_for}")

        # 7. Occasion (Weight: +5 - Gift flow only)
        if flow_type == "Gift" and user_occasion and plant.occasion:
            if user_occasion in plant.occasion:
                score += 5
                reasons.append(f"Appropriate for a {user_occasion} occasion")

        if score > 0:
            scored_plants.append({
                "plant": plant,
                "score": score,
                "reasons": reasons
            })

    # Sort plants by score descending
    scored_plants.sort(key=lambda x: x["score"], reverse=True)

    # Fallback/Relaxation Logic:
    # If we have no plants matching the criteria, relax filters step-by-step
    if not scored_plants:
        # Step 1: Relax to Purpose + Location
        relaxed_answers = {
            "flow_type": flow_type,
            "purpose": user_purpose,
            "location": user_location
        }
        scored_plants = _get_relaxed_recommendations(db, relaxed_answers)
        
        # Step 2: Relax to Purpose only
        if not scored_plants:
            relaxed_answers = {
                "flow_type": flow_type,
                "purpose": user_purpose
            }
            scored_plants = _get_relaxed_recommendations(db, relaxed_answers)
            
        # Step 3: Default to top plants (first 5 in DB)
        if not scored_plants:
            all_plants = db.query(Plant).limit(5).all()
            scored_plants = [{
                "plant": p,
                "score": 1,
                "reasons": ["Popular beginner-friendly choice"]
            } for p in all_plants]

    return scored_plants[:5]

def _get_relaxed_recommendations(db: Session, answers: dict) -> list:
    """Helper method to score plants with fewer search criteria."""
    user_purpose = answers.get("purpose")
    user_location = answers.get("location")
    plants = db.query(Plant).all()
    scored_plants = []

    for plant in plants:
        score = 0
        reasons = []
        if user_purpose and plant.purpose and user_purpose in plant.purpose:
            score += 5
            reasons.append(f"Fits purpose: {user_purpose}")
        if user_location and plant.location and user_location in plant.location:
            score += 3
            reasons.append(f"Suited for placing in {user_location}")

        if score > 0:
            scored_plants.append({
                "plant": plant,
                "score": score,
                "reasons": reasons
            })
    scored_plants.sort(key=lambda x: x["score"], reverse=True)
    return scored_plants
