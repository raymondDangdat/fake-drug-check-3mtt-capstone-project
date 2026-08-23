"""
main.py — FastAPI REST API for FakeDrugChecker
=================================================

Serves the trained ML model as a REST API for mobile/web clients.

Endpoints:
    GET  /         — Root health check
    GET  /health   — Detailed health status
    POST /predict  — Drug verification prediction

Author: FakeDrugChecker Team
"""

import sys
from pathlib import Path
from typing import List
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Add project root to Python path so we can import src modules
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from src.predictor import predict_drug, load_model_artifacts, clear_cache


# ==============================================================================
# Pydantic Models
# ==============================================================================

class DrugCheckRequest(BaseModel):
    """Request body for the /predict endpoint."""
    drug_name: str = Field(default="", description="Name of the drug (e.g., 'Paracetamol')")
    manufacturer: str = Field(default="", description="Manufacturer name")
    nafdac_number: str = Field(default="", description="NAFDAC registration number (e.g., 'A4-7823')")
    barcode: str = Field(default="", description="Product barcode (EAN-13)")
    batch_number: str = Field(default="", description="Manufacturing batch number")
    dosage_form: str = Field(default="", description="Dosage form (Tablet, Capsule, Syrup, etc.)")
    strength: str = Field(default="", description="Drug strength (e.g., '500mg')")
    country: str = Field(default="", description="Country of origin")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "drug_name": "Paracetamol",
                    "manufacturer": "Emzor Pharmaceutical Industries",
                    "nafdac_number": "A4-7823",
                    "barcode": "6190012345670",
                    "batch_number": "BN25-0042",
                    "dosage_form": "Tablet",
                    "strength": "500mg",
                    "country": "Nigeria",
                }
            ]
        }
    }


class DrugCheckResponse(BaseModel):
    """Response body from the /predict endpoint."""
    prediction: str = Field(description="'Genuine' or 'Suspicious'")
    confidence: float = Field(description="Confidence score (0.0 - 1.0)")
    confidence_percent: str = Field(description="Confidence as percentage string (e.g., '94%')")
    explanation: List[str] = Field(description="List of explanation points")
    recommendation: str = Field(description="Actionable recommendation text")


class HealthResponse(BaseModel):
    """Response body for health check endpoints."""
    status: str
    model_loaded: bool
    version: str = "1.0.0"


# ==============================================================================
# App Lifecycle
# ==============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Pre-load model artifacts on startup."""
    try:
        load_model_artifacts()
        print("✅ Model artifacts loaded successfully on startup")
    except FileNotFoundError as e:
        print(f"⚠️ Warning: Could not pre-load model: {e}")
        print("   Run 'python -m src.train_model' first.")
    yield
    clear_cache()
    print("🔌 Model cache cleared on shutdown")


# ==============================================================================
# FastAPI App
# ==============================================================================

app = FastAPI(
    title="FakeDrugChecker API",
    description=(
        "AI-powered drug verification API that predicts whether a drug record "
        "appears **Genuine** or **Suspicious** based on product information. "
        "Provides explainable predictions with confidence scores."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow all origins for mobile app access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==============================================================================
# Endpoints
# ==============================================================================

@app.get("/", response_model=HealthResponse, tags=["Health"])
async def root():
    """Root endpoint — basic health check."""
    try:
        load_model_artifacts()
        model_loaded = True
    except Exception:
        model_loaded = False

    return HealthResponse(
        status="ok",
        model_loaded=model_loaded,
    )


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Detailed health check — confirms model is loaded and ready."""
    try:
        load_model_artifacts()
        return HealthResponse(
            status="healthy",
            model_loaded=True,
        )
    except FileNotFoundError:
        return HealthResponse(
            status="degraded — model not loaded",
            model_loaded=False,
        )


@app.post("/predict", response_model=DrugCheckResponse, tags=["Prediction"])
async def check_drug(request: DrugCheckRequest):
    """
    Predict whether a drug record is Genuine or Suspicious.

    Accepts drug details and returns a prediction with confidence score,
    explanation points, and an actionable recommendation.
    """
    try:
        result = predict_drug(
            drug_name=request.drug_name,
            manufacturer=request.manufacturer,
            nafdac_number=request.nafdac_number,
            barcode=request.barcode,
            batch_number=request.batch_number,
            dosage_form=request.dosage_form,
            strength=request.strength,
            country=request.country,
        )

        return DrugCheckResponse(
            prediction=result["prediction"],
            confidence=result["confidence"],
            confidence_percent=result["confidence_percent"],
            explanation=result["explanation"],
            recommendation=result["recommendation"],
        )

    except FileNotFoundError:
        raise HTTPException(
            status_code=503,
            detail=(
                "Model artifacts not found. Please train the model first "
                "by running: python -m src.train_model"
            ),
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Prediction failed: {str(e)}",
        )


# ==============================================================================
# Run with: uvicorn api.main:app --reload --port 8000
# ==============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api.main:app", host="0.0.0.0", port=8000, reload=True)
