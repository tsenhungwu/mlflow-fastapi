# MLflow FastAPI Demo (PRD)

A machine learning workflow for training and serving Iris flower classifiers using MLflow and FastAPI.

## Architecture

- **MLflow Server** (port 5001): Tracks experiments, logs models, and stores artifacts
- **Training Script**: Trains a Random Forest classifier on the Iris dataset and registers it
- **FastAPI Serving** (port 8000): Loads the latest model and exposes a prediction endpoint

## Setup

### Prerequisites

- Docker and Docker Compose

### Start the Stack

```bash
docker compose up -d
```

This starts MLflow and the FastAPI server. MLflow is available at `http://localhost:5001` and the API at `http://localhost:8000`.

### Train a Model

```bash
docker compose run --rm train
```

This trains a new Random Forest model on the Iris dataset and registers it as `iris_model` in MLflow.

### Make a Prediction

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'
```

Response:

```json
{"prediction": 0}
```

### Check Health

```bash
curl http://localhost:8000/health
```

Response:

```json
{"status": "ok", "model_loaded": true}
```

## Stop the Stack

```bash
docker compose down
```

## Create Multiple Stacks

To run multiple instances with different names:

```bash
docker compose -p my-project-name up -d
```

Stop it with:

```bash
docker compose -p my-project-name down
```

## Project Structure

- `docker-compose.yml`: Service definitions
- `Dockerfile`: Training service image
- `train/train.py`: Model training script
- `app/app.py`: FastAPI application
- `app/requirements.txt`: Python dependencies
- `mlruns/`: MLflow artifacts and runs (auto-generated)
- `mlflow.db`: SQLite backend store (auto-generated)

