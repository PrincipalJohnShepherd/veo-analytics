FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# DB_PATH  — where to write veo_analytics.duckdb (should be on a shared volume)
# DATA_DIR — where the CSV source files are mounted
ENV DB_PATH=/db/veo_analytics.duckdb \
    DATA_DIR=/data

CMD ["sh", "-c", "python setup_db.py && python verify_models.py"]
