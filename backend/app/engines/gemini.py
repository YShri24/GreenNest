import os
import base64
import json
import urllib.request
import urllib.error
import mimetypes

def load_gemini_api_key():
    # 1. First check if it is already in os.environ
    key = os.environ.get("GEMINI_API_KEY")
    if key:
        return key

    # 2. Search for `.env` in possible locations
    current_dir = os.path.dirname(os.path.abspath(__file__))
    paths_to_check = [
        os.path.join(current_dir, ".env"),
        os.path.join(current_dir, "..", ".env"),
        os.path.join(current_dir, "..", "..", ".env"),
        os.path.join(current_dir, "..", "app", ".env"),
    ]
    
    for path in paths_to_check:
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith("#") and "=" in line:
                            k, v = line.split("=", 1)
                            if k.strip() == "GEMINI_API_KEY":
                                val = v.strip()
                                # remove quotes if any
                                if val.startswith('"') and val.endswith('"'):
                                    val = val[1:-1]
                                if val.startswith("'") and val.endswith("'"):
                                    val = val[1:-1]
                                return val
            except Exception as e:
                print(f"Error reading env file at {path}: {e}")
                
    return None

def chat_with_gemini(message: str, history: list, photo_path: str = None) -> dict:
    api_key = load_gemini_api_key()
    if not api_key:
        raise ValueError("GEMINI_API_KEY not found in environment or .env file.")

    # List of candidate models to try in sequence in case of demand spikes or rate limits
    models = [
        "gemini-flash-lite-latest",
        "gemini-2.0-flash-lite",
        "gemini-flash-latest",
        "gemini-pro-latest"
    ]
    
    # Format the conversational history
    history_str = ""
    for msg in history:
        sender_label = "User" if msg.get("sender") == "user" else "Assistant"
        history_str += f"{sender_label}: {msg.get('text')}\n"
        
    prompt = f"""You are the GreenNest Plant Health Assistant, a professional botanist and plant doctor.
Analyze the user's message, the conversational history, and any uploaded image of a plant to identify the plant, detect any health issues, and provide recommendations.

Conversational History:
{history_str}
User's current query: {message}

If an image is provided:
1. Detect the plant species.
2. Analyze the plant's health, identifying any visible symptoms and diagnosing the potential cause (e.g. overwatering, underwatering, light stress, pests, nutrient deficiency, fungal infection, or healthy).
3. Determine a confidence score from 0.0 to 100.0.

Return your response strictly as a JSON object with the following fields:
1. "response": A conversational, friendly, and professional response to the user. Use markdown bold double-asterisks (e.g., **bold**) for emphasis where appropriate (e.g. highlighting treatment steps). Be warm and encouraging.
2. "diagnosis": A short name for the main detected issue/disease (e.g., "Overwatering", "Spider Mites", "Underwatering", "Sunburn", "Healthy"). If no issue/disease is diagnosed or it's a general question, use null.
3. "confidence": A float value between 0.0 and 100.0 representing your confidence. Use 0.0 if no diagnosis is made.
4. "symptoms_found": A list of strings listing the visible symptoms (e.g., ["yellow leaves", "spots on leaves"]).

Response must be valid JSON:
"""

    parts = []
    
    # Add image if provided and exists
    if photo_path and os.path.exists(photo_path):
        try:
            mime_type, _ = mimetypes.guess_type(photo_path)
            if not mime_type:
                mime_type = "image/jpeg"
                
            with open(photo_path, "rb") as f:
                img_data = base64.b64encode(f.read()).decode("utf-8")
                
            parts.append({
                "inlineData": {
                    "mimeType": mime_type,
                    "data": img_data
                }
            })
        except Exception as e:
            print(f"Error encoding image {photo_path} for Gemini: {e}")
            
    # Add prompt text
    parts.append({"text": prompt})
    
    payload = {
        "contents": [
            {
                "parts": parts
            }
        ],
        "generationConfig": {
            "responseMimeType": "application/json"
        }
    }

    last_error = None
    for model in models:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        try:
            with urllib.request.urlopen(req, timeout=25) as response:
                res_data = response.read().decode("utf-8")
                res_json = json.loads(res_data)
                
                # Extract content from response
                text_content = res_json["candidates"][0]["content"]["parts"][0]["text"]
                
                # Clean JSON text if Gemini wrapped it in markdown code block
                cleaned_text = text_content.strip()
                if cleaned_text.startswith("```json"):
                    cleaned_text = cleaned_text[7:]
                if cleaned_text.startswith("```"):
                    cleaned_text = cleaned_text[3:]
                if cleaned_text.endswith("```"):
                    cleaned_text = cleaned_text[:-3]
                cleaned_text = cleaned_text.strip()
                
                return json.loads(cleaned_text)
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8")
            print(f"Gemini API model {model} HTTPError {e.code}: {err_body}")
            last_error = f"HTTP {e.code}: {err_body}"
        except Exception as e:
            print(f"Gemini API model {model} failed: {e}")
            last_error = str(e)
            
    raise Exception(f"All Gemini models failed. Last error: {last_error}")
