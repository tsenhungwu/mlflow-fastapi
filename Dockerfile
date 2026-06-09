FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir mlflow scikit-learn

COPY train/train.py .

CMD ["python", "train.py"]
