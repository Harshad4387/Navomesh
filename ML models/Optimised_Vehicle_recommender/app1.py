import math
import requests
import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all origins (for development)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

if not GOOGLE_API_KEY:
    raise Exception("Google API Key not found in .env file")


# =========================
# REQUEST MODEL
# =========================

class RideRequest(BaseModel):
    start_lat: float
    start_lon: float
    end_lat: float
    end_lon: float


# =========================
# WEATHER (Open-Meteo)
# =========================

def get_weather(lat, lon):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true"

    response = requests.get(url)
    if response.status_code != 200:
        raise HTTPException(status_code=500, detail="Weather API error")

    data = response.json()
    current = data["current_weather"]

    temperature = current["temperature"]
    weather_code = current["weathercode"]

    # Rain codes
    severe_codes = [61, 63, 65, 80, 81, 82]
    severity = 1 if weather_code in severe_codes else 0

    condition = "Rain" if severity else "Clear"

    return {
        "temperature": temperature,
        "condition": condition,
        "severity": severity
    }


# =========================
# TRAFFIC (Google Distance Matrix)
# =========================

def get_traffic(start_lat, start_lon, end_lat, end_lon):

    url = "https://maps.googleapis.com/maps/api/distancematrix/json"

    params = {
        "origins": f"{start_lat},{start_lon}",
        "destinations": f"{end_lat},{end_lon}",
        "departure_time": "now",
        "key": GOOGLE_API_KEY
    }

    response = requests.get(url, params=params)

    if response.status_code != 200:
        raise HTTPException(status_code=500, detail="Google Maps API error")

    data = response.json()

    element = data["rows"][0]["elements"][0]

    if element["status"] != "OK":
        raise HTTPException(status_code=500, detail="Invalid route")

    distance_m = element["distance"]["value"]
    duration = element["duration"]["value"]

    duration_traffic = element.get("duration_in_traffic", {}).get("value", duration)

    traffic_ratio = duration_traffic / duration

    congestion = 1 if traffic_ratio > 1.4 else 0
    description = "Heavy traffic" if congestion else "Smooth traffic"

    return {
        "distance_km": round(distance_m / 1000, 2),
        "congestion": congestion,
        "description": description,
        "duration_min": round(duration_traffic / 60, 1)
    }


# =========================
# VEHICLE RANKING
# =========================

def rank_vehicles(distance_km, weather_sev, traffic_cong):

    scores = {
        "bike": 0,
        "auto": 0,
        "cab": 0
    }

    # Weather impact
    if weather_sev == 1:
        scores["cab"] += 3
        scores["auto"] += 1
        scores["bike"] -= 2
    else:
        scores["bike"] += 2
        scores["auto"] += 1

    # Traffic impact
    if traffic_cong == 1:
        scores["bike"] += 2
        scores["auto"] += 1
    else:
        scores["cab"] += 1

    # Distance impact
    if distance_km < 3:
        scores["bike"] += 2
    elif distance_km < 7:
        scores["auto"] += 2
    else:
        scores["cab"] += 2

    ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)

    return [vehicle for vehicle, score in ranked]


# =========================
# MAIN RECOMMENDATION
# =========================

def get_recommendation(start_lat, start_lon, end_lat, end_lon):

    weather = get_weather(start_lat, start_lon)
    traffic = get_traffic(start_lat, start_lon, end_lat, end_lon)

    distance_km = traffic["distance_km"]

    ranking = rank_vehicles(
        distance_km,
        weather["severity"],
        traffic["congestion"]
    )

    # Fare calculation (base model)
    bike_fare = round(distance_km * 6, 2)
    auto_fare = round(distance_km * 15, 2)
    cab_fare = round(distance_km * 18, 2)

    fare_map = {
        "bike": bike_fare,
        "auto": auto_fare,
        "cab": cab_fare
    }

    ranked_output = []

    for vehicle in ranking:
        ranked_output.append({
            "type": vehicle,
            "fare": fare_map[vehicle]
        })

    return {
        "weather": weather,
        "traffic": {
            "congestion_level": traffic["congestion"],
            "description": traffic["description"],
            "eta_minutes": traffic["duration_min"]
        },
        "distance_km": distance_km,
        "ranking": ranked_output
    }


# =========================
# API ENDPOINT
# =========================

@app.post("/recommend")
def recommend(data: RideRequest):
    return get_recommendation(
        data.start_lat,
        data.start_lon,
        data.end_lat,
        data.end_lon
    )