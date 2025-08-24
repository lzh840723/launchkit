import jwt
import time
from dotenv import load_dotenv
import os

load_dotenv()
SECRET_KEY = os.getenv("SECRET_KEY", "change_me_in_env")
print("Generating with SECRET_KEY:", SECRET_KEY)  # 打印密钥确认
print("Current .env path:", os.path.abspath('.env'))  # 打印路径确认

payload = {"user": "test", "exp": time.time() + 3600}  # 标准 payload
token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
print("New token:", token)