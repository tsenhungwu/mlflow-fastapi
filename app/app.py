import os
import mlflow.pyfunc

from fastapi import FastAPI
from pydantic import BaseModel
import asyncio

app = FastAPI()

mlflow.set_tracking_uri(os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5001"))

model = None

async def load_model_async():
    global model
    await asyncio.sleep(3)
    try:
        # Load directly from the artifact directory
        model_path = "/mlruns/0/models/m-34e25784d278404c9d4e51525a6c4a94/artifacts"
        # Try to find the latest model
        import glob
        model_paths = sorted(glob.glob("/mlruns/0/models/*/artifacts"), reverse=True)
        if model_paths:
            model_path = model_paths[0]
            model = mlflow.pyfunc.load_model(model_path)
            print(f"Model loaded from {model_path}")
        else:
            print("No model artifacts found")
    except Exception as e:
        print(f"Failed to load model: {e}")
        model = None

@app.on_event("startup")
async def startup_event():
    await load_model_async()

class IrisRequest(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float

@app.post("/predict")
def predict(data: IrisRequest):
    if model is None:
        return {"error": "Model not loaded"}

    features = [[
        data.sepal_length,
        data.sepal_width,
        data.petal_length,
        data.petal_width
    ]]

    prediction = model.predict(features)

    return {
        "prediction": int(prediction[0])
    }

@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": model is not None}
