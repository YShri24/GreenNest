import json
from decimal import Decimal
from app.database import SessionLocal, Base, engine
from app.models import Plant, DiagnosisRule, User

def seed_database():
    db = SessionLocal()
    try:
        # Clear existing tables to reset seeds (optional but helpful for development testing)
        print("Clearing existing tables...")
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        
        print("Seeding initial data...")
        
        # 1. Create default mock users
        user_umang = User(
            user_id=1,
            name="Umang",
            email="umang@greennest.com",
            mobile="9876543210",
            address="123 Garden Lane, Green City",
            password="password",
            role="User"
        )
        user_normal = User(
            user_id=2,
            name="Normal User",
            email="user@greennest.com",
            mobile="1234567890",
            address="456 Flower Ave, Green City",
            password="user123",
            role="User"
        )
        user_admin = User(
            user_id=3,
            name="Admin Owner",
            email="admin@greennest.com",
            mobile="9999999999",
            address="789 Forest Boulevard, Green City",
            password="admin123",
            role="Admin"
        )
        db.add_all([user_umang, user_normal, user_admin])

        # 2. Add Plants Catalog
        plants = [
            Plant(
                name="Snake Plant",
                category="Indoor",
                description="Also known as Mother-in-Law's Tongue, the Snake Plant is incredibly resilient and perfect for beginners. It features upright, sword-like leaves with yellow borders.",
                price=Decimal("399.00"),
                stock=15,
                sunlight="Low to Bright Indirect",
                water_frequency="Every 2-3 weeks",
                image_url="https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&q=80&w=400",
                purpose=["Air Purification", "Decoration", "Good Luck", "Stress Relief"],
                location=["Bedroom", "Living Room", "Office Desk", "Kitchen"],
                light=["Low", "Medium", "Bright Indirect"],
                season=["All Season", "Summer", "Monsoon", "Winter"],
                maintenance="Low",
                gift_for=["Friend", "Colleague", "Mother", "Teacher"],
                occasion=["Birthday", "Housewarming", "Thank You", "Just Because"]
            ),
            Plant(
                name="ZZ Plant",
                category="Indoor",
                description="With its shiny, dark green leaves, the ZZ plant adds a premium touch to any interior. It is highly drought-tolerant and thrives on neglect.",
                price=Decimal("499.00"),
                stock=12,
                sunlight="Low to Medium Indirect",
                water_frequency="Monthly",
                image_url="https://images.unsplash.com/photo-1632207191173-e3973950cf0f?auto=format&fit=crop&q=80&w=400",
                purpose=["Decoration", "Office Desk", "Good Luck"],
                location=["Bedroom", "Living Room", "Office Desk"],
                light=["Low", "Medium"],
                season=["All Season", "Summer", "Winter"],
                maintenance="Low",
                gift_for=["Colleague", "Friend", "Spouse", "Brother"],
                occasion=["Housewarming", "Anniversary", "Birthday", "Just Because"]
            ),
            Plant(
                name="Peace Lily",
                category="Indoor",
                description="The Peace Lily produces gorgeous white spade-like blooms and has deep green foliage. It is a champion at air purification but will droop dramatically when thirsty.",
                price=Decimal("299.00"),
                stock=8,
                sunlight="Medium Indirect",
                water_frequency="Weekly",
                image_url="https://images.unsplash.com/photo-1593691509543-c55fb32e7355?auto=format&fit=crop&q=80&w=400",
                purpose=["Air Purification", "Decoration", "Stress Relief", "Balcony Beautification"],
                location=["Bedroom", "Living Room", "Balcony"],
                light=["Low", "Medium"],
                season=["All Season", "Monsoon"],
                maintenance="Medium",
                gift_for=["Mother", "Sister", "Teacher", "Spouse"],
                occasion=["Anniversary", "Wedding", "Birthday", "Festival"]
            ),
            Plant(
                name="Money Plant (Golden Pothos)",
                category="Indoor/Outdoor",
                description="A fast-growing climbing vine with heart-shaped variegated leaves. Symbolizes wealth, prosperity, and good luck in feng shui.",
                price=Decimal("249.00"),
                stock=25,
                sunlight="Bright Indirect to Medium",
                water_frequency="Every 5-7 days",
                image_url="https://images.unsplash.com/photo-1596436889106-be35e843f974?auto=format&fit=crop&q=80&w=400",
                purpose=["Good Luck", "Air Purification", "Balcony Beautification", "Decoration"],
                location=["Living Room", "Balcony", "Office Desk", "Kitchen", "Terrace"],
                light=["Medium", "Bright Indirect"],
                season=["All Season", "Summer", "Monsoon"],
                maintenance="Low",
                gift_for=["Friend", "Colleague", "Spouse", "Sister", "Brother"],
                occasion=["Housewarming", "Birthday", "Festival", "Graduation"]
            ),
            Plant(
                name="Rose Plant",
                category="Outdoor",
                description="Classic red rose plant that blooms continuously with proper care and full sunlight. Represents deep love, affection, and decoration.",
                price=Decimal("349.00"),
                stock=10,
                sunlight="Direct Sunlight",
                water_frequency="Daily",
                image_url="https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&q=80&w=400",
                purpose=["Decoration", "Love & Affection", "Gardening Hobby"],
                location=["Balcony", "Garden", "Terrace"],
                light=["Direct Sunlight"],
                season=["Winter", "Summer"],
                maintenance="High",
                gift_for=["Spouse", "Mother", "Sister"],
                occasion=["Anniversary", "Wedding", "Birthday", "Festival"]
            ),
            Plant(
                name="Tulsi (Holy Basil)",
                category="Medicinal",
                description="A sacred herbal plant in Hindu households with numerous medicinal benefits for immunity, stress relief, and breathing health.",
                price=Decimal("199.00"),
                stock=30,
                sunlight="Direct Sunlight to Bright Indirect",
                water_frequency="Daily",
                image_url="https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=400",
                purpose=["Medicinal Use", "Good Luck", "Stress Relief", "Gardening Hobby"],
                location=["Balcony", "Garden", "Terrace", "Kitchen"],
                light=["Direct Sunlight", "Bright Indirect"],
                season=["All Season", "Summer"],
                maintenance="Low",
                gift_for=["Mother", "Father", "Teacher", "Friend"],
                occasion=["Festival", "Housewarming", "Birthday", "Thank You"]
            ),
            Plant(
                name="Spider Plant",
                category="Indoor",
                description="Known for its arching spider-like leaves and tiny hanging plantlets, the Spider Plant is non-toxic to pets and removes toxins from air.",
                price=Decimal("229.00"),
                stock=20,
                sunlight="Medium to Bright Indirect",
                water_frequency="Weekly",
                image_url="https://images.unsplash.com/photo-1572656631137-7935297eff55?auto=format&fit=crop&q=80&w=400",
                purpose=["Air Purification", "Decoration", "Office Desk", "Stress Relief"],
                location=["Bedroom", "Living Room", "Office Desk", "Kitchen"],
                light=["Medium", "Bright Indirect"],
                season=["All Season", "Summer"],
                maintenance="Low",
                gift_for=["Friend", "Colleague", "Brother", "Sister"],
                occasion=["Housewarming", "Birthday", "Graduation", "Thank You"]
            ),
            Plant(
                name="Aloe Vera",
                category="Medicinal",
                description="A thick, fleshy succulent containing soothing gel widely used for skin care, burns, and health juices. Prefers dry soil and bright light.",
                price=Decimal("179.00"),
                stock=18,
                sunlight="Bright Direct Sunlight",
                water_frequency="Every 2 weeks",
                image_url="https://images.unsplash.com/photo-1596547610010-090c8853b6fa?auto=format&fit=crop&q=80&w=400",
                purpose=["Medicinal Use", "Air Purification", "Office Desk", "Decoration"],
                location=["Bedroom", "Balcony", "Office Desk", "Kitchen", "Terrace"],
                light=["Bright Indirect", "Direct Sunlight"],
                season=["All Season", "Summer"],
                maintenance="Low",
                gift_for=["Mother", "Father", "Friend", "Teacher"],
                occasion=["Thank You", "Get Well Soon", "Birthday", "Just Because"]
            )
        ]
        db.add_all(plants)

        # 3. Add Plant Disease Diagnostic Rules
        rules = [
            DiagnosisRule(
                cause="Overwatering",
                symptom_tags=["yellow leaves", "soft stem", "mushy soil"],
                context_tags=["frequent watering", "low light", "no drainage"],
                confidence_base=Decimal("0.65")
            ),
            DiagnosisRule(
                cause="Underwatering",
                symptom_tags=["dry crispy leaves", "drooping", "cracked soil"],
                context_tags=["rare watering", "direct sun", "low humidity"],
                confidence_base=Decimal("0.60")
            ),
            DiagnosisRule(
                cause="Low light stress",
                symptom_tags=["leggy growth", "pale new leaves", "slow growth"],
                context_tags=["low light", "bedroom", "office"],
                confidence_base=Decimal("0.55")
            ),
            DiagnosisRule(
                cause="Pest Infestation",
                symptom_tags=["spots on leaves", "webbing on leaves", "holes in leaves"],
                context_tags=["high humidity", "crowded plants"],
                confidence_base=Decimal("0.70")
            ),
            DiagnosisRule(
                cause="Nutrient Deficiency",
                symptom_tags=["pale veins", "slow growth", "yellow leaves"],
                context_tags=["no fertilizing history", "old soil"],
                confidence_base=Decimal("0.50")
            )
        ]
        db.add_all(rules)

        db.commit()
        print("Database seeded successfully with 8 plants and 5 diagnostic rules!")
        
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
        raise e
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
