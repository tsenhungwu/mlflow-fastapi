import asyncio
import os
from contextlib import asynccontextmanager

import mlflow.pyfunc
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

mlflow.set_tracking_uri(
    os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5001")
)

model = None


async def load_model_async():
    global model
    try:
        model_uri = os.getenv("MODEL_URI", "models:/iris_model/latest")
        model = mlflow.pyfunc.load_model(model_uri)
        print(f"Model loaded from model URI: {model_uri}")
    except Exception as e:
        raise Exception(f"Failed to load model: {e}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await load_model_async()
    yield


app = FastAPI(lifespan=lifespan)


class IrisRequest(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float


@app.post("/predict")
def predict(data: IrisRequest):
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    features = [
        [
            data.sepal_length,
            data.sepal_width,
            data.petal_length,
            data.petal_width,
        ]
    ]

    prediction = model.predict(features)

    return {"prediction": int(prediction[0])}


@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": model is not None}
