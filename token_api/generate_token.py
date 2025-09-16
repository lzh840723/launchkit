import jwt
import time
from dotenv import load_dotenv
import os

load_dotenv()
SECRET_KEY = os.getenv("SECRET_KEY")
print("Generating with SECRET_KEY:", SECRET_KEY)  # Print secret key for confirmation
print("Current .env path:", os.path.abspath('.env'))  # Print .env path for confirmation

payload = {"user": "test", "exp": time.time() + 3600}  # Standard payload
token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
print("New token:", token)
