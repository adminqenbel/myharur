import requests
import json

url = "https://myharur.onrender.com/auth/google"
data = {
    "email": "testgoogle@example.com",
    "first_name": "Test",
    "last_name": "Google",
    "photo_url": "https://example.com/photo.png"
}
headers = {'Content-Type': 'application/json'}

try:
    response = requests.post(url, json=data, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")
except Exception as e:
    print(f"Error: {e}")
