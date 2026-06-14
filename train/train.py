import mlflow
import mlflow.sklearn
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier

X, y = load_iris(return_X_y=True)

model = RandomForestClassifier()

model.fit(X, y)

with mlflow.start_run() as run:
    mlflow.sklearn.log_model(
        model, "model", registered_model_name="iris_model"
    )
    print(f"RUN_ID={run.info.run_id}")
