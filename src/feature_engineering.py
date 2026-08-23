"""
feature_engineering.py — Text Feature Extraction
==================================================

This module creates text features from drug record fields:
    - Combined text feature from multiple columns
    - TF-IDF Vectorization
    - CountVectorizer (for comparison)

Author: FakeDrugChecker Team
"""

from typing import Tuple, Optional

import pandas as pd
import scipy.sparse
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer

from src.utils import logger


# ==============================================================================
# Combined Text Feature
# ==============================================================================

def create_combined_text(df: pd.DataFrame) -> pd.Series:
    """
    Create a single combined text feature by concatenating multiple columns.

    Columns used: DrugName, Manufacturer, NAFDAC_Number, Barcode,
                  BatchNumber, DosageForm, Strength, Country.

    Args:
        df: DataFrame with drug record columns.

    Returns:
        pd.Series containing the combined text for each record.

    Example:
        >>> combined = create_combined_text(df)
        >>> print(combined.iloc[0])
        'paracetamol emzor pharmaceutical industries a4-7823 6190012345678 ...'
    """
    columns_to_combine = [
        "DrugName", "Manufacturer", "NAFDAC_Number", "Barcode",
        "BatchNumber", "DosageForm", "Strength", "Country",
    ]

    # Ensure all columns exist and are string type
    for col in columns_to_combine:
        if col not in df.columns:
            logger.warning(f"Column '{col}' not found in DataFrame, using empty string")
            df[col] = ""

    combined = df[columns_to_combine].astype(str).agg(" ".join, axis=1)

    logger.info(f"Combined text feature created from {len(columns_to_combine)} columns")
    logger.info(f"Average text length: {combined.str.len().mean():.0f} characters")

    return combined


# ==============================================================================
# TF-IDF Vectorization
# ==============================================================================

def build_tfidf_features(
    text_series: pd.Series,
    max_features: int = 5000,
    ngram_range: Tuple[int, int] = (1, 2),
    vectorizer: Optional[TfidfVectorizer] = None,
) -> Tuple[scipy.sparse.spmatrix, TfidfVectorizer]:
    """
    Transform text data into TF-IDF feature matrix.

    Uses unigrams and bigrams by default for better pattern capture.

    Args:
        text_series: Series of text strings to vectorize.
        max_features: Maximum number of features (default: 5000).
        ngram_range: Tuple of (min_n, max_n) for n-gram range.
        vectorizer: Pre-fitted vectorizer for transform-only mode.
                    If None, fits a new vectorizer.

    Returns:
        Tuple of (sparse feature matrix, fitted TfidfVectorizer).

    Example:
        >>> X_tfidf, tfidf_vec = build_tfidf_features(combined_text)
        >>> print(f"Feature matrix shape: {X_tfidf.shape}")
    """
    if vectorizer is None:
        vectorizer = TfidfVectorizer(
            max_features=max_features,
            ngram_range=ngram_range,
            stop_words="english",
            sublinear_tf=True,       # Apply sublinear TF scaling
            min_df=2,                # Ignore terms appearing in < 2 documents
            max_df=0.95,             # Ignore terms appearing in > 95% of documents
        )
        X = vectorizer.fit_transform(text_series)
        logger.info(
            f"TF-IDF fitted: {X.shape[0]} samples × {X.shape[1]} features "
            f"(ngram_range={ngram_range}, max_features={max_features})"
        )
    else:
        X = vectorizer.transform(text_series)
        logger.info(f"TF-IDF transformed: {X.shape[0]} samples × {X.shape[1]} features")

    return X, vectorizer


# ==============================================================================
# CountVectorizer (for comparison)
# ==============================================================================

def build_count_features(
    text_series: pd.Series,
    max_features: int = 5000,
    ngram_range: Tuple[int, int] = (1, 2),
    vectorizer: Optional[CountVectorizer] = None,
) -> Tuple[scipy.sparse.spmatrix, CountVectorizer]:
    """
    Transform text data into Count (Bag-of-Words) feature matrix.

    Used for comparison with TF-IDF approach.

    Args:
        text_series: Series of text strings to vectorize.
        max_features: Maximum number of features (default: 5000).
        ngram_range: Tuple of (min_n, max_n) for n-gram range.
        vectorizer: Pre-fitted vectorizer for transform-only mode.

    Returns:
        Tuple of (sparse feature matrix, fitted CountVectorizer).
    """
    if vectorizer is None:
        vectorizer = CountVectorizer(
            max_features=max_features,
            ngram_range=ngram_range,
            stop_words="english",
            min_df=2,
            max_df=0.95,
        )
        X = vectorizer.fit_transform(text_series)
        logger.info(
            f"CountVectorizer fitted: {X.shape[0]} samples × {X.shape[1]} features"
        )
    else:
        X = vectorizer.transform(text_series)
        logger.info(f"CountVectorizer transformed: {X.shape[0]} samples × {X.shape[1]} features")

    return X, vectorizer


# ==============================================================================
# Main — Feature engineering standalone
# ==============================================================================

if __name__ == "__main__":
    from src.utils import load_dataset
    from src.preprocessing import preprocess_pipeline

    print("=" * 60)
    print("  FakeDrugChecker — Feature Engineering")
    print("=" * 60)

    df = load_dataset()
    df_clean, le = preprocess_pipeline(df, save_cleaned=False)

    combined = create_combined_text(df_clean)
    print(f"\nCombined text sample:\n{combined.iloc[0]}\n")

    X_tfidf, tfidf_vec = build_tfidf_features(combined)
    print(f"TF-IDF shape: {X_tfidf.shape}")

    X_count, count_vec = build_count_features(combined)
    print(f"CountVectorizer shape: {X_count.shape}")

    # Show top features
    feature_names = tfidf_vec.get_feature_names_out()
    print(f"\nTop 20 TF-IDF features: {list(feature_names[:20])}")
