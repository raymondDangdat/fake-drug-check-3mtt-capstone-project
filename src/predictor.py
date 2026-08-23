"""
predictor.py — Drug Prediction with Explanations
===================================================

This module provides the main prediction interface:
    - Load saved model artifacts
    - Accept drug details as input
    - Return prediction, confidence score, and explanation
    - Rule-based explanation engine for interpretability

Author: FakeDrugChecker Team
"""

import re
import os
from typing import Dict, Any, Optional, List

import numpy as np
import pandas as pd
import joblib

from src.utils import (
    logger, MODELS_DIR,
    KNOWN_MANUFACTURERS, KNOWN_DRUG_NAMES, NAFDAC_PATTERN,
)
from src.feature_engineering import create_combined_text, build_tfidf_features


# ==============================================================================
# Model Loader (Singleton Pattern)
# ==============================================================================

_cached_artifacts: Dict[str, Any] = {}


def load_model_artifacts(
    model_path: Optional[str] = None,
    vectorizer_path: Optional[str] = None,
    label_encoder_path: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Load trained model, vectorizer, and label encoder from disk.

    Uses caching to avoid reloading on every prediction call.

    Args:
        model_path: Path to the model .pkl file.
        vectorizer_path: Path to the vectorizer .pkl file.
        label_encoder_path: Path to the label encoder .pkl file.

    Returns:
        Dict with keys: 'model', 'vectorizer', 'label_encoder'.

    Raises:
        FileNotFoundError: If any artifact file is missing.
    """
    global _cached_artifacts

    if _cached_artifacts:
        return _cached_artifacts

    # Default paths
    if model_path is None:
        model_path = str(MODELS_DIR / "fake_drug_model.pkl")
    if vectorizer_path is None:
        vectorizer_path = str(MODELS_DIR / "vectorizer.pkl")
    if label_encoder_path is None:
        label_encoder_path = str(MODELS_DIR / "label_encoder.pkl")

    # Validate files exist
    for name, path in [("Model", model_path), ("Vectorizer", vectorizer_path),
                       ("Label Encoder", label_encoder_path)]:
        if not os.path.exists(path):
            raise FileNotFoundError(
                f"{name} not found at '{path}'. "
                "Please run train_model.py first."
            )

    # Load artifacts
    _cached_artifacts = {
        "model": joblib.load(model_path),
        "vectorizer": joblib.load(vectorizer_path),
        "label_encoder": joblib.load(label_encoder_path),
    }

    logger.info("Model artifacts loaded successfully")
    return _cached_artifacts


def clear_cache() -> None:
    """Clear the cached model artifacts (useful for reloading after retraining)."""
    global _cached_artifacts
    _cached_artifacts = {}
    logger.info("Model cache cleared")


# ==============================================================================
# Explanation Engine
# ==============================================================================

def _check_nafdac_pattern(nafdac: str) -> Dict[str, Any]:
    """
    Check if NAFDAC number matches the valid pattern.

    Valid pattern: Letter + Digit + '-' + 4 Digits (e.g., A4-7823).

    Args:
        nafdac: NAFDAC registration number string.

    Returns:
        Dict with 'valid' (bool) and 'message' (str).
    """
    nafdac_clean = nafdac.strip().upper()

    if not nafdac_clean or nafdac_clean in ("UNKNOWN", "N/A", "NONE", "PENDING", "NOT REGISTERED"):
        return {
            "valid": False,
            "message": "⚠️ NAFDAC number is missing or marked as unregistered",
        }

    if re.match(NAFDAC_PATTERN, nafdac_clean):
        return {
            "valid": True,
            "message": "✅ NAFDAC number matches valid registration pattern",
        }

    return {
        "valid": False,
        "message": f"⚠️ NAFDAC number '{nafdac}' does not match expected format (e.g., A4-7823)",
    }


def _check_manufacturer(manufacturer: str) -> Dict[str, Any]:
    """
    Check if manufacturer is a known legitimate Nigerian company.

    Args:
        manufacturer: Manufacturer name string.

    Returns:
        Dict with 'known' (bool) and 'message' (str).
    """
    mfr_clean = manufacturer.strip().lower()

    if not mfr_clean or mfr_clean in ("unknown", "n/a", "none"):
        return {
            "known": False,
            "message": "⚠️ Manufacturer name is missing or unknown",
        }

    if mfr_clean in KNOWN_MANUFACTURERS:
        return {
            "known": True,
            "message": f"✅ '{manufacturer}' is a recognized Nigerian pharmaceutical company",
        }

    # Partial match (fuzzy)
    for known in KNOWN_MANUFACTURERS:
        if mfr_clean in known or known in mfr_clean:
            return {
                "known": True,
                "message": f"✅ '{manufacturer}' partially matches known manufacturer",
            }

    return {
        "known": False,
        "message": f"⚠️ '{manufacturer}' is not a recognized manufacturer in our database",
    }


def _check_barcode(barcode: str) -> Dict[str, Any]:
    """
    Check if barcode is a valid EAN-13 format.

    Valid: 13 numeric digits.

    Args:
        barcode: Barcode string.

    Returns:
        Dict with 'valid' (bool) and 'message' (str).
    """
    barcode_clean = barcode.strip()

    if not barcode_clean or barcode_clean in ("unknown", "n/a", "none"):
        return {
            "valid": False,
            "message": "⚠️ Barcode is missing",
        }

    # Check if it's 13 digits
    if re.match(r"^\d{13}$", barcode_clean):
        # Verify EAN-13 check digit
        digits = [int(d) for d in barcode_clean]
        total = sum(d * (1 if i % 2 == 0 else 3) for i, d in enumerate(digits[:12]))
        check = (10 - (total % 10)) % 10
        if check == digits[12]:
            return {
                "valid": True,
                "message": "✅ Barcode is a valid EAN-13 format with correct check digit",
            }
        else:
            return {
                "valid": False,
                "message": "⚠️ Barcode has 13 digits but check digit is incorrect",
            }

    if not barcode_clean.isdigit():
        return {
            "valid": False,
            "message": f"⚠️ Barcode contains non-numeric characters",
        }

    return {
        "valid": False,
        "message": f"⚠️ Barcode length is {len(barcode_clean)} (expected 13 for EAN-13)",
    }


def _check_drug_name(drug_name: str) -> Dict[str, Any]:
    """
    Check if drug name matches known legitimate drug names.

    Args:
        drug_name: Drug name string.

    Returns:
        Dict with 'known' (bool) and 'message' (str).
    """
    name_clean = drug_name.strip().lower()

    if not name_clean or name_clean in ("unknown", "n/a", "none"):
        return {
            "known": False,
            "message": "⚠️ Drug name is missing",
        }

    if name_clean in KNOWN_DRUG_NAMES:
        return {
            "known": True,
            "message": f"✅ '{drug_name}' is a recognized drug name",
        }

    # Partial match
    for known in KNOWN_DRUG_NAMES:
        if name_clean in known or known in name_clean:
            return {
                "known": True,
                "message": f"✅ '{drug_name}' partially matches a known drug",
            }

    return {
        "known": False,
        "message": f"⚠️ '{drug_name}' is not in our database of known drugs",
    }


def _check_country(country: str) -> Dict[str, Any]:
    """
    Check the country of origin.

    Args:
        country: Country string.

    Returns:
        Dict with 'expected' (bool) and 'message' (str).
    """
    country_clean = country.strip().lower()

    if country_clean == "nigeria":
        return {
            "expected": True,
            "message": "✅ Country of origin is Nigeria",
        }
    elif country_clean in ("unknown", "n/a", "none", ""):
        return {
            "expected": False,
            "message": "⚠️ Country of origin is unknown",
        }
    else:
        return {
            "expected": False,
            "message": f"⚠️ Country of origin '{country}' — verify import registration",
        }


def generate_explanation(
    drug_name: str,
    manufacturer: str,
    nafdac_number: str,
    barcode: str,
    country: str,
    prediction: str,
    confidence: float,
) -> List[str]:
    """
    Generate a human-readable explanation for the prediction.

    Combines rule-based checks with the ML model's confidence
    to produce actionable explanations.

    Args:
        drug_name: Drug name.
        manufacturer: Manufacturer name.
        nafdac_number: NAFDAC registration number.
        barcode: Barcode string.
        country: Country of origin.
        prediction: Model prediction ('Genuine' or 'Suspicious').
        confidence: Model confidence score (0-1).

    Returns:
        List of explanation strings.
    """
    explanations = []

    # Run all checks
    nafdac_check = _check_nafdac_pattern(nafdac_number)
    mfr_check = _check_manufacturer(manufacturer)
    barcode_check = _check_barcode(barcode)
    drug_check = _check_drug_name(drug_name)
    country_check = _check_country(country)

    # Add relevant explanations
    explanations.append(nafdac_check["message"])
    explanations.append(mfr_check["message"])
    explanations.append(barcode_check["message"])
    explanations.append(drug_check["message"])
    explanations.append(country_check["message"])

    # Add confidence context
    if confidence >= 0.90:
        explanations.append(f"🔍 Model confidence is very high ({confidence:.0%})")
    elif confidence >= 0.70:
        explanations.append(f"🔍 Model confidence is moderate ({confidence:.0%})")
    else:
        explanations.append(f"🔍 Model confidence is low ({confidence:.0%}) — manual review recommended")

    # Count red flags
    red_flags = sum([
        not nafdac_check.get("valid", True),
        not mfr_check.get("known", True),
        not barcode_check.get("valid", True),
        not drug_check.get("known", True),
        not country_check.get("expected", True),
    ])

    if prediction == "Suspicious":
        explanations.append(f"🚩 {red_flags} out of 5 checks flagged potential issues")
    else:
        explanations.append(f"✅ {5 - red_flags} out of 5 checks passed")

    return explanations


def generate_recommendation(prediction: str, confidence: float) -> str:
    """
    Generate an actionable recommendation based on the prediction.

    Args:
        prediction: 'Genuine' or 'Suspicious'.
        confidence: Model confidence (0-1).

    Returns:
        Recommendation string.
    """
    if prediction == "Genuine" and confidence >= 0.85:
        return (
            "✅ This drug appears to be genuine based on our analysis. "
            "However, always verify with your pharmacist and check "
            "the NAFDAC website for official registration."
        )
    elif prediction == "Genuine" and confidence < 0.85:
        return (
            "⚠️ This drug appears genuine but with moderate confidence. "
            "We recommend verifying the NAFDAC number on the official "
            "NAFDAC website and consulting your pharmacist."
        )
    elif prediction == "Suspicious" and confidence >= 0.85:
        return (
            "🚨 HIGH ALERT: This drug shows strong indicators of being "
            "suspicious. Do NOT consume this product. Report to NAFDAC "
            "at nafdac.gov.ng or call their hotline. Consult a licensed "
            "pharmacist immediately."
        )
    else:
        return (
            "⚠️ This drug shows some suspicious indicators. Exercise "
            "caution and verify with NAFDAC before use. Consult your "
            "pharmacist for professional advice."
        )


# ==============================================================================
# Main Prediction Function
# ==============================================================================

def predict_drug(
    drug_name: str = "",
    manufacturer: str = "",
    nafdac_number: str = "",
    barcode: str = "",
    batch_number: str = "",
    dosage_form: str = "",
    strength: str = "",
    country: str = "",
) -> Dict[str, Any]:
    """
    Predict whether a drug record is Genuine or Suspicious.

    This is the main prediction interface. It loads the trained model,
    processes the input, makes a prediction, and generates an explanation.

    Args:
        drug_name: Name of the drug (e.g., 'Paracetamol').
        manufacturer: Manufacturer name (e.g., 'Emzor Pharmaceutical Industries').
        nafdac_number: NAFDAC registration number (e.g., 'A4-7823').
        barcode: Product barcode (e.g., '6190012345678').
        batch_number: Batch/lot number (e.g., 'BN25-0042').
        dosage_form: Dosage form (e.g., 'Tablet').
        strength: Drug strength (e.g., '500mg').
        country: Country of origin (e.g., 'Nigeria').

    Returns:
        Dict with keys:
            - prediction: 'Genuine' or 'Suspicious'
            - confidence: float (0-1)
            - confidence_percent: str (e.g., '94%')
            - explanation: List[str] — detailed explanation points
            - recommendation: str — actionable recommendation
            - input_data: Dict — the original input

    Example:
        >>> result = predict_drug(
        ...     drug_name="Paracetamol",
        ...     manufacturer="Unknown Company",
        ...     nafdac_number="INVALID",
        ...     barcode="12345",
        ...     country="China",
        ... )
        >>> print(result['prediction'])
        'Suspicious'
        >>> print(result['confidence_percent'])
        '94%'
    """
    # Load model artifacts
    artifacts = load_model_artifacts()
    model = artifacts["model"]
    vectorizer = artifacts["vectorizer"]
    label_encoder = artifacts["label_encoder"]

    # Create input DataFrame (single row)
    input_data = {
        "DrugName": drug_name.strip().lower() if drug_name else "unknown",
        "Manufacturer": manufacturer.strip().lower() if manufacturer else "unknown",
        "NAFDAC_Number": nafdac_number.strip().lower() if nafdac_number else "unknown",
        "Barcode": barcode.strip().lower() if barcode else "unknown",
        "BatchNumber": batch_number.strip().lower() if batch_number else "unknown",
        "DosageForm": dosage_form.strip().lower() if dosage_form else "unknown",
        "Strength": strength.strip().lower() if strength else "unknown",
        "Country": country.strip().lower() if country else "unknown",
    }

    df_input = pd.DataFrame([input_data])

    # Create combined text feature
    combined = create_combined_text(df_input)

    # Transform using the saved vectorizer (not fit!)
    X_input, _ = build_tfidf_features(combined, vectorizer=vectorizer)

    # Predict
    y_pred_encoded = model.predict(X_input)[0]
    prediction = label_encoder.inverse_transform([y_pred_encoded])[0]

    # Get confidence score
    if hasattr(model, "predict_proba"):
        proba = model.predict_proba(X_input)[0]
        confidence = float(np.max(proba))
    elif hasattr(model, "decision_function"):
        # For SVC without calibration
        decision = model.decision_function(X_input)[0]
        confidence = float(1 / (1 + np.exp(-abs(decision))))  # Sigmoid approx
    else:
        confidence = 0.5  # Unknown confidence

    # Generate explanation
    explanation = generate_explanation(
        drug_name=drug_name,
        manufacturer=manufacturer,
        nafdac_number=nafdac_number,
        barcode=barcode,
        country=country,
        prediction=prediction,
        confidence=confidence,
    )

    # Generate recommendation
    recommendation = generate_recommendation(prediction, confidence)

    result = {
        "prediction": prediction,
        "confidence": confidence,
        "confidence_percent": f"{confidence:.0%}",
        "explanation": explanation,
        "recommendation": recommendation,
        "input_data": {
            "DrugName": drug_name,
            "Manufacturer": manufacturer,
            "NAFDAC_Number": nafdac_number,
            "Barcode": barcode,
            "BatchNumber": batch_number,
            "DosageForm": dosage_form,
            "Strength": strength,
            "Country": country,
        },
    }

    logger.info(f"Prediction: {prediction} (Confidence: {confidence:.2%})")
    return result


# ==============================================================================
# Main — Test predictions
# ==============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("  FakeDrugChecker — Prediction Demo")
    print("=" * 60)

    # Test 1: Genuine drug
    print("\n--- Test 1: Genuine Drug ---")
    result1 = predict_drug(
        drug_name="Paracetamol",
        manufacturer="Emzor Pharmaceutical Industries",
        nafdac_number="A4-7823",
        barcode="6190012345670",
        batch_number="BN25-0042",
        dosage_form="Tablet",
        strength="500mg",
        country="Nigeria",
    )
    print(f"Prediction:  {result1['prediction']}")
    print(f"Confidence:  {result1['confidence_percent']}")
    print(f"Explanation:")
    for exp in result1['explanation']:
        print(f"  {exp}")
    print(f"Recommendation: {result1['recommendation']}")

    # Test 2: Suspicious drug
    print("\n--- Test 2: Suspicious Drug ---")
    result2 = predict_drug(
        drug_name="Super Paracetmol",
        manufacturer="QuickCure Labs",
        nafdac_number="INVALID123",
        barcode="12345",
        batch_number="???",
        dosage_form="Tablet",
        strength="500mg",
        country="China",
    )
    print(f"Prediction:  {result2['prediction']}")
    print(f"Confidence:  {result2['confidence_percent']}")
    print(f"Explanation:")
    for exp in result2['explanation']:
        print(f"  {exp}")
    print(f"Recommendation: {result2['recommendation']}")
