"""
Triage ML service for the AI-Powered Telemedicine Chatbot.

Loads the model exported by notebooks/03_evaluate_export.ipynb and serves:
  GET  /health   -> service status and model info
  POST /predict  -> {"text": "..."} -> triage level, confidence and probabilities

Run (from the ml folder, with the venv active):
  uvicorn app:app --host 127.0.0.1 --port 8000
"""
import os
from contextlib import asynccontextmanager
from pathlib import Path

import joblib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

MODEL_PATH = Path(os.getenv('MODEL_PATH', Path(__file__).parent / 'models' / 'triage_model.joblib'))

state = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    if not MODEL_PATH.exists():
        raise RuntimeError(f'Model file not found: {MODEL_PATH}. Run notebook 03 first.')
    bundle = joblib.load(MODEL_PATH)
    state.update(bundle)
    state['classes'] = list(bundle['model'].classes_)
    print(f"Loaded {bundle['model_name']} (version {bundle['version']}), "
          f"emergency threshold {bundle['emergency_threshold']}")
    yield
    state.clear()


app = FastAPI(title='Telemedicine Triage ML Service', version='1.0.0', lifespan=lifespan)


class PredictRequest(BaseModel):
    text: str = Field(..., min_length=2, max_length=2000, description="Patient's symptom description")


class PredictResponse(BaseModel):
    triage: str
    confidence: float
    probabilities: dict[str, float]
    emergency_rule_applied: bool
    model_version: str


def predict_one(text: str) -> dict:
    model = state['model']
    classes = state['classes']
    proba = model.predict_proba([text])[0]

    top = classes[int(proba.argmax())]
    p_emergency = float(proba[classes.index('emergency')])
    rule = top != 'emergency' and p_emergency >= state['emergency_threshold']
    triage = 'emergency' if rule else top

    return {
        'triage': triage,
        'confidence': round(float(proba.max()), 4),
        'probabilities': {c: round(float(p), 4) for c, p in zip(classes, proba)},
        'emergency_rule_applied': rule,
        'model_version': state['version'],
    }


@app.get('/health')
def health():
    return {
        'status': 'ok',
        'model': state.get('model_name'),
        'version': state.get('version'),
        'emergency_threshold': state.get('emergency_threshold'),
        'test_metrics': state.get('test_metrics'),
    }


@app.post('/predict', response_model=PredictResponse)
def predict(req: PredictRequest):
    text = req.text.strip()
    if len(text) < 2:
        raise HTTPException(status_code=400, detail='Text is too short')
    return predict_one(text)