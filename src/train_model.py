"""
train_model.py — Model Training and Selection
===============================================

This module trains multiple ML classifiers and selects the best one:
    - Logistic Regression
    - Multinomial Naive Bayes
    - Linear SVC (with calibration for probability)
    - Random Forest

The best model is chosen based on F1 Score and saved to disk.

Author: FakeDrugChecker Team
"""

import os
from typing import Dict, Any, Tuple, Optional

import numpy as np
import pandas as pd
import joblib
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.linear_model import LogisticRegression
from sklearn.naive_bayes import MultinomialNB
from sklearn.svm import LinearSVC
from sklearn.calibration import CalibratedClassifierCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import f1_score, accuracy_score, precision_score, recall_score
from sklearn.preprocessing import LabelEncoder

from src.utils import (
    logger, MODELS_DIR, DATA_DIR,
    generate_synthetic_dataset, load_dataset,
)
from src.preprocessing import preprocess_pipeline
from src.feature_engineering import create_combined_text, build_tfidf_features


# ==============================================================================
# Model Definitions
# ==============================================================================

def get_models() -> Dict[str, Any]:
    """
    Return a dictionary of ML models to train and compare.

    Returns:
        Dict mapping model names to sklearn estimator instances.
    """
    return {
        "Logistic Regression": LogisticRegression(
            max_iter=1000,
            C=1.0,
            solver="lbfgs",
            random_state=42,
        ),
        "Multinomial Naive Bayes": MultinomialNB(
            alpha=1.0,
        ),
        "Linear SVC": CalibratedClassifierCV(
            estimator=LinearSVC(
                max_iter=2000,
                C=1.0,
                random_state=42,
            ),
            cv=3,
        ),
        "Random Forest": RandomForestClassifier(
            n_estimators=200,
            max_depth=None,
            min_samples_split=5,
            random_state=42,
            n_jobs=-1,
        ),
    }


# ==============================================================================
# Training Pipeline
# ==============================================================================

def train_and_compare(
    X_train: Any,
    X_test: Any,
    y_train: np.ndarray,
    y_test: np.ndarray,
    cv_folds: int = 5,
) -> Tuple[Dict[str, Dict[str, float]], str, Any]:
    """
    Train all models, evaluate them, and identify the best one.

    Args:
        X_train: Training feature matrix (sparse or dense).
        X_test: Test feature matrix.
        y_train: Training labels.
        y_test: Test labels.
        cv_folds: Number of cross-validation folds (default: 5).

    Returns:
        Tuple of:
            - results: Dict of model name → metrics dict
            - best_model_name: Name of the best model
            - best_model: The best fitted model instance
    """
    models = get_models()
    results = {}
    best_f1 = 0.0
    best_model_name = ""
    best_model = None

    logger.info(f"Training {len(models)} models...")
    logger.info(f"Training set: {X_train.shape[0]} samples")
    logger.info(f"Test set: {X_test.shape[0]} samples")
    logger.info("-" * 60)

    for name, model in models.items():
        logger.info(f"\n▶ Training: {name}")

        # Train
        model.fit(X_train, y_train)

        # Predict
        y_pred = model.predict(X_test)

        # Compute metrics
        acc = accuracy_score(y_test, y_pred)
        prec = precision_score(y_test, y_pred, average="weighted", zero_division=0)
        rec = recall_score(y_test, y_pred, average="weighted", zero_division=0)
        f1 = f1_score(y_test, y_pred, average="weighted", zero_division=0)

        # Cross-validation
        cv_scores = cross_val_score(model, X_train, y_train, cv=cv_folds, scoring="f1_weighted")

        results[name] = {
            "accuracy": acc,
            "precision": prec,
            "recall": rec,
            "f1_score": f1,
            "cv_mean": cv_scores.mean(),
            "cv_std": cv_scores.std(),
        }

        logger.info(f"  Accuracy:  {acc:.4f}")
        logger.info(f"  Precision: {prec:.4f}")
        logger.info(f"  Recall:    {rec:.4f}")
        logger.info(f"  F1 Score:  {f1:.4f}")
        logger.info(f"  CV F1:     {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")

        # Track best model
        if f1 > best_f1:
            best_f1 = f1
            best_model_name = name
            best_model = model

    logger.info("=" * 60)
    logger.info(f"🏆 Best Model: {best_model_name} (F1 = {best_f1:.4f})")
    logger.info("=" * 60)

    return results, best_model_name, best_model


# ==============================================================================
# Model Saving
# ==============================================================================

def save_model_artifacts(
    model: Any,
    vectorizer: Any,
    label_encoder: LabelEncoder,
    model_name: str = "fake_drug_model",
) -> Dict[str, str]:
    """
    Save the trained model, vectorizer, and label encoder to disk.

    Args:
        model: Trained sklearn model.
        vectorizer: Fitted TfidfVectorizer.
        label_encoder: Fitted LabelEncoder.
        model_name: Base name for the model file.

    Returns:
        Dict mapping artifact names to their file paths.
    """
    paths = {}

    # Save model
    model_path = str(MODELS_DIR / f"{model_name}.pkl")
    joblib.dump(model, model_path)
    paths["model"] = model_path
    logger.info(f"Model saved: {model_path}")

    # Save vectorizer
    vec_path = str(MODELS_DIR / "vectorizer.pkl")
    joblib.dump(vectorizer, vec_path)
    paths["vectorizer"] = vec_path
    logger.info(f"Vectorizer saved: {vec_path}")

    # Save label encoder
    le_path = str(MODELS_DIR / "label_encoder.pkl")
    joblib.dump(label_encoder, le_path)
    paths["label_encoder"] = le_path
    logger.info(f"Label encoder saved: {le_path}")

    return paths


# ==============================================================================
# Full Training Pipeline
# ==============================================================================

def run_training_pipeline(
    data_path: Optional[str] = None,
    test_size: float = 0.2,
    random_state: int = 42,
) -> Dict[str, Any]:
    """
    Execute the complete training pipeline end-to-end.

    Steps:
        1. Load or generate dataset
        2. Preprocess data
        3. Create features (TF-IDF)
        4. Split into train/test
        5. Train and compare all models
        6. Save the best model

    Args:
        data_path: Path to the dataset CSV. If None, generates a new one.
        test_size: Fraction of data for testing (default: 0.2).
        random_state: Random seed for reproducibility.

    Returns:
        Dict with keys: 'results', 'best_model_name', 'best_model',
        'vectorizer', 'label_encoder', 'X_test', 'y_test', 'y_pred'.
    """
    logger.info("=" * 60)
    logger.info("  FakeDrugChecker — Training Pipeline")
    logger.info("=" * 60)

    # Step 1: Load or generate dataset
    if data_path and os.path.exists(data_path):
        df = load_dataset(data_path)
    else:
        synthetic_path = str(DATA_DIR / "synthetic_drugs.csv")
        if os.path.exists(synthetic_path):
            df = load_dataset(synthetic_path)
        else:
            logger.info("No dataset found. Generating synthetic dataset...")
            df = generate_synthetic_dataset(n_records=2000, random_seed=42)

    # Step 2: Preprocess
    df_clean, label_encoder = preprocess_pipeline(df, save_cleaned=True)

    # Step 3: Feature engineering
    combined_text = create_combined_text(df_clean)
    X, vectorizer = build_tfidf_features(combined_text)
    y = df_clean["Label_Encoded"].values

    # Step 4: Train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=random_state, stratify=y
    )
    logger.info(f"Train/test split: {X_train.shape[0]} / {X_test.shape[0]}")

    # Step 5: Train and compare
    results, best_model_name, best_model = train_and_compare(
        X_train, X_test, y_train, y_test
    )

    # Step 6: Save artifacts
    save_model_artifacts(best_model, vectorizer, label_encoder)

    # Final predictions for evaluation
    y_pred = best_model.predict(X_test)

    # Get probability scores if available
    y_proba = None
    if hasattr(best_model, "predict_proba"):
        y_proba = best_model.predict_proba(X_test)

    return {
        "results": results,
        "best_model_name": best_model_name,
        "best_model": best_model,
        "vectorizer": vectorizer,
        "label_encoder": label_encoder,
        "X_train": X_train,
        "X_test": X_test,
        "y_train": y_train,
        "y_test": y_test,
        "y_pred": y_pred,
        "y_proba": y_proba,
        "df_clean": df_clean,
    }


# ==============================================================================
# Main — Run training standalone
# ==============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("  FakeDrugChecker — Model Training")
    print("=" * 60)

    pipeline_output = run_training_pipeline()

    print("\n" + "=" * 60)
    print("  Model Comparison Results")
    print("=" * 60)

    results_df = pd.DataFrame(pipeline_output["results"]).T
    results_df = results_df.round(4)
    print(results_df.to_string())

    print(f"\n🏆 Best Model: {pipeline_output['best_model_name']}")
    print(f"   F1 Score:   {pipeline_output['results'][pipeline_output['best_model_name']]['f1_score']:.4f}")
    print("\n✅ Model artifacts saved to models/ directory")
