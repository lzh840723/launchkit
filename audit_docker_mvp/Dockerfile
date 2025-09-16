# Base image: lightweight Python 3.12
FROM python:3.12-slim

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app 

# Copy dependency file
COPY requirements.txt .  

# Install dependencies without cache
RUN pip install --no-cache-dir -r requirements.txt  

# Copy all source code
COPY . .  

# Expose application port
EXPOSE 8000  

# Mount volume for HDD data persistence
VOLUME /app/data  

# Startup command
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]  
