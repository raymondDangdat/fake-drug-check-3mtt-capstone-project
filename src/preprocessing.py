"""
preprocessing.py — Data Cleaning and Preprocessing Pipeline
=============================================================

This module handles all data cleaning tasks:
    - Duplicate removal
    - Missing value handling
    - Text normalization (lowercase, strip whitespace, fix typos)
    - Label encoding
    - Full preprocessing pipeline

Author: FakeDrugChecker Team
"""

import re
from typing import Tuple

import numpy as np
import pandas as pd
from sklearn.preprocessing import LabelEncoder

from src.utils import logger, save_dataset


# ==============================================================================
# Individual Cleaning Functions
# ==============================================================================

def remove_duplicates(df: pd.DataFrame) -> pd.DataFrame:
    """
    Remove duplicate rows from the dataset.

    Args:
        df: Input DataFrame.

    Returns:
        DataFrame with duplicates removed.
    """
    original_count = len(df)
    df = df.drop_duplicates().reset_index(drop=True)
    removed = original_count - len(df)
    logger.info(f"Removed {removed} duplicate rows ({original_count} → {len(df)})")
    return df


def handle_missing_values(df: pd.DataFrame) -> pd.DataFrame:
    """
    Handle missing values in the dataset.

    Strategy:
        - For text columns: fill with 'unknown'
        - For ExpiryDate: fill with 'unknown'
        - Log the number of missing values per column

    Args:
        df: Input DataFrame.

    Returns:
        DataFrame with missing values handled.
    """
    missing_counts = df.isnull().sum()
    total_missing = missing_counts.sum()

    if total_missing > 0:
        logger.info(f"Missing values found ({total_missing} total):")
        for col in missing_counts[missing_counts > 0].index:
            logger.info(f"  - {col}: {missing_counts[col]} missing")

    # Fill all missing values with 'unknown'
    text_columns = [
        "DrugName", "Manufacturer", "NAFDAC_Number", "Barcode",
        "BatchNumber", "ExpiryDate", "DosageForm", "Strength",
        "PackageSize", "Country",
    ]

    for col in text_columns:
        if col in df.columns:
            df[col] = df[col].fillna("unknown")

    logger.info("Missing values filled with 'unknown'")
    return df


def normalize_text(df: pd.DataFrame) -> pd.DataFrame:
    """
    Normalize text fields in the dataset.

    Operations:
        - Convert to lowercase
        - Strip leading/trailing whitespace
        - Collapse multiple spaces into single space
        - Remove special characters that are just noise

    Args:
        df: Input DataFrame.

    Returns:
        DataFrame with normalized text fields.
    """
    text_columns = [
        "DrugName", "Manufacturer", "NAFDAC_Number", "Barcode",
        "BatchNumber", "DosageForm", "Strength", "PackageSize", "Country",
    ]

    for col in text_columns:
        if col in df.columns:
            df[col] = (
                df[col]
                .astype(str)
                .str.lower()
                .str.strip()
                .apply(lambda x: re.sub(r'\s+', ' ', x))  # collapse multiple spaces
            )

    logger.info("Text normalization complete (lowercase, strip, collapse spaces)")
    return df


def encode_labels(df: pd.DataFrame) -> Tuple[pd.DataFrame, LabelEncoder]:
    """
    Encode the 'Label' column using LabelEncoder.

    Mapping: Genuine → 0, Suspicious → 1 (alphabetical order).

    Args:
        df: Input DataFrame with 'Label' column.

    Returns:
        Tuple of (DataFrame with encoded 'Label_Encoded' column, fitted LabelEncoder).

    Raises:
        ValueError: If 'Label' column is missing.
    """
    if "Label" not in df.columns:
        raise ValueError("DataFrame must contain a 'Label' column")

    le = LabelEncoder()
    df["Label_Encoded"] = le.fit_transform(df["Label"])

    logger.info(f"Label encoding: {dict(zip(le.classes_, le.transform(le.classes_)))}")
    return df, le


# ==============================================================================
# Full Preprocessing Pipeline
# ==============================================================================

def preprocess_pipeline(
    df: pd.DataFrame,
    save_cleaned: bool = True,
) -> Tuple[pd.DataFrame, LabelEncoder]:
    """
    Run the complete data preprocessing pipeline.

    Steps:
        1. Remove duplicates
        2. Handle missing values
        3. Normalize text
        4. Encode labels

    Args:
        df: Raw input DataFrame.
        save_cleaned: If True, saves cleaned data to data/drugs.csv.

    Returns:
        Tuple of (cleaned DataFrame, fitted LabelEncoder).

    Example:
        >>> from src.utils import load_dataset
        >>> df = load_dataset()
        >>> df_clean, label_encoder = preprocess_pipeline(df)
        >>> print(df_clean.shape)
    """
    logger.info("=" * 50)
    logger.info("Starting preprocessing pipeline...")
    logger.info("=" * 50)

    # Step 1: Remove duplicates
    df = remove_duplicates(df)

    # Step 2: Handle missing values
    df = handle_missing_values(df)

    # Step 3: Normalize text
    df = normalize_text(df)

    # Step 4: Encode labels
    df, le = encode_labels(df)

    logger.info(f"Preprocessing complete. Final shape: {df.shape}")
    logger.info(f"Label distribution:\n{df['Label'].value_counts().to_string()}")

    # Save cleaned dataset
    if save_cleaned:
        save_dataset(df, filename="drugs.csv")

    return df, le


# ==============================================================================
# Main — Run preprocessing standalone
# ==============================================================================

if __name__ == "__main__":
    from src.utils import load_dataset

    print("=" * 60)
    print("  FakeDrugChecker — Data Preprocessing")
    print("=" * 60)

    df = load_dataset()
    df_clean, le = preprocess_pipeline(df)

    print(f"\nCleaned dataset shape: {df_clean.shape}")
    print(f"\nSample:\n{df_clean.head()}")
    print(f"\nLabel mapping: {dict(zip(le.classes_, le.transform(le.classes_)))}")
