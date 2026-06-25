import os
import sys
import subprocess

def run_server():
    print("=== GreenNest Backend API Server Starter ===")
    
    # 1. Install dependencies if not already met
    print("Checking backend requirements...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("Dependencies verified!")
    except Exception as e:
        print(f"Warning: Failed to auto-install dependencies: {e}")
        print("Please run manually: pip install -r requirements.txt")

    # 2. Check if database needs seeding
    db_file = "greennest.db"
    if not os.path.exists(db_file):
        print(f"Database file '{db_file}' not found. Seeding initial data...")
        try:
            subprocess.check_call([sys.executable, "-m", "app.seed"])
        except Exception as e:
            print(f"Error seeding database: {e}")
    else:
        print("Database found. Skipping seed.")

    # 3. Launch Uvicorn Server
    print("Starting FastAPI Uvicorn Server on http://127.0.0.1:8000")
    print("Interactive API Docs will be available at http://127.0.0.1:8000/docs")
    try:
        import uvicorn
        uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
    except KeyboardInterrupt:
        print("\nStopping GreenNest Backend API Server...")
    except Exception as e:
        print(f"Error starting server: {e}")

if __name__ == "__main__":
    run_server()
