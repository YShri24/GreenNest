from sqlalchemy.orm import Session
from app.models import DiagnosisRule, PlantCard, HealthLog

def diagnose_plant(db: Session, symptoms: list, context: dict, plant_card_id: int = None) -> dict:
    """
    Diagnoses plant issues based on:
    - Symptom tags (e.g. yellow leaves, soft stem)
    - Context tags (e.g. frequent watering, low light)
    - PlantCard history (optional)
    
    Scoring:
    - Visual symptom matched: +5
    - Context tag matched: +3
    - PlantCard history matched: +5
    - Species-specific rule match: +2
    """
    # Normalize inputs
    cleaned_symptoms = [s.lower().strip() for s in symptoms]
    
    location = context.get("location", "")
    light = context.get("light", "")
    water_frequency = context.get("water_frequency", "")
    
    # Compile context tags
    context_tags = []
    if location:
        context_tags.append(location.lower())
    if light:
        context_tags.append(f"{light.lower()} light")
    if water_frequency:
        # map "Daily" or "Every few days" to "frequent watering"
        if water_frequency.lower() in ["daily", "every few days"]:
            context_tags.append("frequent watering")
        elif water_frequency.lower() in ["weekly", "rarely"]:
            context_tags.append("rare watering")
            
    # Fetch plant card context if available
    plant_card = None
    history_multiplier = 1.0
    has_history = False
    
    if plant_card_id:
        plant_card = db.query(PlantCard).filter(PlantCard.plant_card_id == plant_card_id).first()
        if plant_card:
            has_history = True
            # Pull context from card
            if plant_card.location:
                context_tags.append(plant_card.location.lower())
            if plant_card.light_exposure:
                context_tags.append(f"{plant_card.light_exposure.lower()} light")
            if plant_card.water_frequency:
                if plant_card.water_frequency.lower() in ["daily", "every few days", "frequent"]:
                    context_tags.append("frequent watering")
                else:
                    context_tags.append("rare watering")

    # Fetch all rules
    rules = db.query(DiagnosisRule).all()
    scored_results = []

    for rule in rules:
        score = 0
        matches = []
        
        # 1. Visual Symptoms Match (+5 each)
        rule_symptoms = [s.lower() for s in rule.symptom_tags] if rule.symptom_tags else []
        for sym in cleaned_symptoms:
            if sym in rule_symptoms:
                score += 5
                matches.append(f"Detected symptom: {sym}")

        # 2. Context Tags Match (+3 each)
        rule_contexts = [c.lower() for c in rule.context_tags] if rule.context_tags else []
        for ctx in context_tags:
            if ctx in rule_contexts:
                score += 3
                matches.append(f"Matched context: {ctx}")

        # 3. PlantCard History Match (+5)
        # If previous health logs indicate this same diagnosis, increase score
        if plant_card:
            prev_logs = db.query(HealthLog).filter(
                HealthLog.plant_card_id == plant_card_id,
                HealthLog.entry_type == "Diagnosis"
            ).all()
            for log in prev_logs:
                if log.diagnosis and log.diagnosis.lower() == rule.cause.lower():
                    score += 5
                    matches.append("Matches plant history of similar symptoms")
                    break

        # 4. Species specific checks (+2)
        # (e.g. Succulents or Monsteras having specific issues)
        if plant_card and plant_card.species:
            species_lower = plant_card.species.lower()
            if "succulent" in species_lower or "cactus" in species_lower:
                if rule.cause.lower() == "overwatering":
                    score += 2
                    matches.append("Succulents are highly susceptible to overwatering")
            if "monstera" in species_lower:
                if rule.cause.lower() == "low light stress":
                    score += 2
                    matches.append("Monsteras require bright indirect light to split leaves")

        if score > 0:
            # Base confidence calculation
            base_conf = float(rule.confidence_base) if rule.confidence_base else 0.60
            # Scale confidence based on matches (cap at 95%)
            conf = min(0.95, base_conf + (score / 40.0))
            scored_results.append({
                "cause": rule.cause,
                "score": score,
                "confidence": round(conf * 100, 1),
                "matches": matches,
                "steps": get_treatment_steps(rule.cause)
            })

    # Sort results
    scored_results.sort(key=lambda x: x["score"], reverse=True)

    # Fallback/Relaxation Logic:
    # If no rules match, relax filters
    if not scored_results:
        # Step 1: Default checklist based on symptoms
        if cleaned_symptoms:
            scored_results = [{
                "cause": "General Environmental Stress",
                "score": 5,
                "confidence": 55.0,
                "matches": [f"Visual indicators: {', '.join(cleaned_symptoms)}"],
                "steps": [
                    "Isolate the plant to prevent spreading pests",
                    "Check soil moisture (mushy vs dry)",
                    "Ensure adequate drainage at bottom of pot",
                    "Place in indirect sunlight for stabilization"
                ]
            }]
        # Step 2: Ultimate fallback
        else:
            scored_results = [{
                "cause": "General Care Adjustment Needed",
                "score": 1,
                "confidence": 45.0,
                "matches": ["Unspecified context"],
                "steps": [
                    "Water only when top 2 inches of soil are dry",
                    "Wipe leaves with a damp cloth to allow maximum light absorption",
                    "Check for root health/rot by gently pulling plant out of pot"
                ]
            }]

    # Main diagnosis is the top scored result, with alternates
    primary = scored_results[0]
    alternates = scored_results[1:3] if len(scored_results) > 1 else []
    
    return {
        "primary": primary,
        "alternates": alternates,
        "history_used": has_history
    }

def get_treatment_steps(cause: str) -> list:
    """Helper returns treatment steps based on cause."""
    cause_lower = cause.lower()
    if "overwatering" in cause_lower:
        return [
            "Skip watering for the next 5-7 days.",
            "Improve airflow around the pot.",
            "Check the drainage tray and empty any standing water.",
            "Trim fully yellowed or decaying leaves."
        ]
    elif "underwatering" in cause_lower:
        return [
            "Give the soil a thorough soak until water drains out of the bottom.",
            "Mist leaves to increase local humidity.",
            "Water regularly when the top 1 inch of soil feels dry.",
            "Prune off completely dry, crispy leaves."
        ]
    elif "light" in cause_lower:
        return [
            "Move the plant closer to a window (preferably East or South facing).",
            "Rotate the pot 90 degrees weekly for even growth.",
            "If natural light is unavailable, consider a grow light."
        ]
    elif "pest" in cause_lower:
        return [
            "Wipe leaves with a mild neem oil solution or insecticidal soap.",
            "Isolate the plant from other house plants immediately.",
            "Prune heavily infested leaves and discard them."
        ]
    elif "nutrient" in cause_lower:
        return [
            "Apply a balanced liquid fertilizer at half strength.",
            "Repot in fresh, nutrient-rich soil mix if not done in over a year.",
            "Ensure the watering pH is balanced."
        ]
    else:
        return [
            "Prune dead or dying leaves.",
            "Move to a bright location away from drafty windows.",
            "Monitor soil moisture carefully before watering."
        ]
