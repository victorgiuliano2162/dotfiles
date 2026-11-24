#!/usr/bin/python3
import json
import urllib.request

URL = (
    "https://api.open-meteo.com/v1/forecast"
    "?latitude=-7.96188&longitude=-34.84037"
    "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m"
    "&timezone=America/Recife"
)

try:
    with urllib.request.urlopen(URL, timeout=4) as resp:
        data = json.load(resp)
    c = data["current"]
    temp = c["temperature_2m"]
    feels = c["apparent_temperature"]
    hum = c["relative_humidity_2m"]
    wind = c["wind_speed_10m"]

    output = {
        "text": f"{temp:.1f}°C",
        "tooltip": (
            f"Rio Doce, Olinda - PE\n"
            f"Temperatura: {temp:.1f}°C\n"
            f"Sensação térmica: {feels:.1f}°C\n"
            f"Umidade: {hum}%\n"
            f"Vento: {wind:.1f} km/h"
        ),
    }
except Exception:
    output = {
        "text": "N/D",
        "tooltip": "Clima indisponível no momento",
    }

print(json.dumps(output, ensure_ascii=False))
