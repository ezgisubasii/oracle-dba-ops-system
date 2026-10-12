#Small python image that runs the oracle health check
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY monitoring/ monitoring/

ENTRYPOINT ["python", "monitoring/health_check.py"]

