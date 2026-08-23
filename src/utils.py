"""
utils.py — Utility Functions and Synthetic Dataset Generator
=============================================================

This module provides:
    - Synthetic dataset generation with realistic Nigerian drug data
    - File I/O helpers for loading and saving datasets
    - Path configuration for the project
    - Logging setup

Author: FakeDrugChecker Team
"""

import os
import random
import string
import logging
from typing import Optional
from pathlib import Path

import numpy as np
import pandas as pd

# ==============================================================================
# Project Paths
# ==============================================================================

# Resolve paths relative to the project root (one level up from src/)
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"
MODELS_DIR = PROJECT_ROOT / "models"
SCREENSHOTS_DIR = PROJECT_ROOT / "screenshots"

# Ensure directories exist
for _dir in [DATA_DIR, MODELS_DIR, SCREENSHOTS_DIR]:
    _dir.mkdir(parents=True, exist_ok=True)


# ==============================================================================
# Logging Setup
# ==============================================================================

def setup_logger(name: str = "FakeDrugChecker", level: int = logging.INFO) -> logging.Logger:
    """
    Configure and return a project logger.

    Args:
        name: Logger name.
        level: Logging level (default: INFO).

    Returns:
        Configured logging.Logger instance.
    """
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            "[%(asctime)s] %(levelname)s — %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    logger.setLevel(level)
    return logger


logger = setup_logger()


# ==============================================================================
# Constants — Drug Data for Nigeria
# ==============================================================================

# Real Nigerian drug names (commonly used)
GENUINE_DRUG_NAMES = [
    "Paracetamol", "Amoxicillin", "Metronidazole", "Artemether Lumefantrine",
    "Ciprofloxacin", "Vitamin C", "Emzor Paracetamol", "Lonart", "Panadol",
    "Flagyl", "Augmentin", "Ampiclox", "ORS", "Ibuprofen", "Diclofenac",
    "Chloroquine", "Coartem", "Amatem", "Loperamide", "Vitamin B Complex",
    "Folic Acid", "Ferrous Sulphate", "Amoxil", "Tetracycline",
    "Erythromycin", "Cotrimoxazole", "Doxycycline", "Gentamicin",
    "Ceftriaxone", "Azithromycin", "Prednisolone", "Hydrocortisone",
    "Omeprazole", "Ranitidine", "Antacid", "Multivitamin",
    "Tramadol", "Diazepam", "Chlorpheniramine", "Promethazine",
    "Metformin", "Glibenclamide", "Amlodipine", "Lisinopril",
    "Atenolol", "Nifedipine", "Furosemide", "Spironolactone",
]

# Legitimate Nigerian pharmaceutical manufacturers
GENUINE_MANUFACTURERS = [
    "Emzor Pharmaceutical Industries", "May & Baker Nigeria Plc",
    "Fidson Healthcare Plc", "GlaxoSmithKline Nigeria",
    "Swiss Pharma Nigeria Ltd", "Chi Pharmaceuticals Ltd",
    "Neimeth International Pharmaceuticals", "Dana Pharmaceuticals Ltd",
    "Drugfield Pharmaceuticals Ltd", "Evans Medical Plc",
    "Juhel Nigeria Ltd", "Mopson Pharmaceutical Ltd",
    "Nigerian German Chemicals Plc", "Pharma Deko Plc",
    "SKG Pharma Ltd", "Tuyil Pharmaceutical Industries",
    "Bioraj Pharmaceuticals Ltd", "Hovid Nigeria Ltd",
    "Sanofi Nigeria", "Pfizer Nigeria",
]

# Fictitious manufacturers (for suspicious records)
FAKE_MANUFACTURERS = [
    "Healwell Pharma Ltd", "QuickCure Labs", "MegaDrug Industries",
    "GoodHealth Generics", "PharmaFast Nigeria", "Sunrise Medications",
    "TopNotch Drugs Ltd", "CureFast Pharmaceuticals", "DrugKing Industries",
    "BestPills International", "MedExpress Ltd", "WonderDrug Co",
    "PharmaPlus International", "FastRelief Drugs", "HealthMax Pharma",
    "NovaDrug Industries", "BioFix Pharmaceuticals", "MedLine Drugs Ltd",
    "SuperCure Pharma", "AlphaHealth Industries",
]

# Dosage forms
DOSAGE_FORMS = [
    "Tablet", "Capsule", "Syrup", "Suspension", "Injection",
    "Cream", "Ointment", "Drops", "Powder", "Sachet",
]

# Drug strengths
STRENGTHS = [
    "500mg", "250mg", "100mg", "200mg", "400mg",
    "10mg", "20mg", "50mg", "5mg", "1g",
    "125mg/5ml", "250mg/5ml", "500mg/5ml",
]

# Package sizes
PACKAGE_SIZES = [
    "10 tablets", "20 tablets", "30 tablets", "100 tablets",
    "10 capsules", "20 capsules", "60ml bottle", "100ml bottle",
    "200ml bottle", "1 vial", "5 vials", "1 tube", "30g tube",
]

# Countries
COUNTRIES_GENUINE = ["Nigeria"]
COUNTRIES_SUSPICIOUS = [
    "Nigeria", "China", "India", "Unknown", "Pakistan", "Ghana",
]


# ==============================================================================
# Helper Functions
# ==============================================================================

def _generate_valid_nafdac(index: int) -> str:
    """
    Generate a valid-looking NAFDAC registration number.

    Format: XX-XXXX where X is alphanumeric.
    Example: A4-7823, 04-1234

    Args:
        index: Record index (for variety).

    Returns:
        A realistic NAFDAC number string.
    """
    prefix = random.choice(string.ascii_uppercase) + str(random.randint(0, 9))
    suffix = f"{random.randint(1000, 9999)}"
    return f"{prefix}-{suffix}"


def _generate_invalid_nafdac() -> str:
    """
    Generate an intentionally invalid NAFDAC number.

    Creates various types of invalid patterns:
    - Missing dash
    - Too short / too long
    - All letters
    - Random strings

    Returns:
        An invalid NAFDAC number string.
    """
    patterns = [
        # Missing dash
        lambda: f"{''.join(random.choices(string.ascii_uppercase + string.digits, k=6))}",
        # Too short
        lambda: f"{random.choice(string.ascii_uppercase)}-{random.randint(10, 99)}",
        # Too long
        lambda: f"{random.choice(string.ascii_uppercase)}{random.randint(0,9)}-{random.randint(100000, 999999)}",
        # All letters
        lambda: f"{''.join(random.choices(string.ascii_uppercase, k=2))}-{''.join(random.choices(string.ascii_uppercase, k=4))}",
        # No prefix
        lambda: f"-{random.randint(1000, 9999)}",
        # Random gibberish
        lambda: ''.join(random.choices(string.ascii_letters + string.digits, k=random.randint(3, 10))),
        # N/A or empty-ish
        lambda: random.choice(["N/A", "PENDING", "NOT REGISTERED", "NONE"]),
    ]
    return random.choice(patterns)()


def _generate_valid_barcode() -> str:
    """
    Generate a valid-looking EAN-13 barcode (13 digits).

    Starts with country prefix 619 (Nigeria) for realism.

    Returns:
        A 13-digit barcode string.
    """
    # Nigerian GS1 prefix: 619
    body = "619" + ''.join([str(random.randint(0, 9)) for _ in range(9)])
    # Calculate check digit (EAN-13 algorithm)
    total = 0
    for i, digit in enumerate(body):
        total += int(digit) * (1 if i % 2 == 0 else 3)
    check = (10 - (total % 10)) % 10
    return body + str(check)


def _generate_invalid_barcode() -> str:
    """
    Generate an intentionally invalid barcode.

    Returns:
        A malformed barcode string.
    """
    patterns = [
        # Too short
        lambda: ''.join([str(random.randint(0, 9)) for _ in range(random.randint(5, 10))]),
        # Too long
        lambda: ''.join([str(random.randint(0, 9)) for _ in range(random.randint(15, 20))]),
        # Contains letters
        lambda: ''.join(random.choices(string.ascii_letters + string.digits, k=13)),
        # All zeros
        lambda: "0000000000000",
        # Repeated digits
        lambda: str(random.randint(1, 9)) * 13,
    ]
    return random.choice(patterns)()


def _generate_batch_number(genuine: bool = True) -> str:
    """
    Generate a batch number.

    Args:
        genuine: If True, generates a realistic batch number.

    Returns:
        A batch number string.
    """
    if genuine:
        prefix = random.choice(["BN", "BT", "LOT", "L", "B"])
        year = random.choice(["24", "25", "26"])
        number = f"{random.randint(100, 9999):04d}"
        return f"{prefix}{year}-{number}"
    else:
        # Suspicious batch numbers
        patterns = [
            lambda: ''.join(random.choices(string.ascii_letters, k=random.randint(3, 8))),
            lambda: str(random.randint(1, 99)),
            lambda: "BATCH-" + ''.join(random.choices(string.digits, k=3)),
            lambda: random.choice(["N/A", "UNKNOWN", "??", "---"]),
        ]
        return random.choice(patterns)()


def _generate_expiry_date(genuine: bool = True) -> str:
    """
    Generate an expiry date string.

    Args:
        genuine: If True, generates a future date. Otherwise, may generate past dates.

    Returns:
        Expiry date as string (YYYY-MM-DD or various formats).
    """
    if genuine:
        year = random.choice([2026, 2027, 2028, 2029])
        month = random.randint(1, 12)
        day = random.randint(1, 28)
        return f"{year}-{month:02d}-{day:02d}"
    else:
        # Suspicious: expired, invalid format, or missing
        patterns = [
            # Already expired
            lambda: f"{random.choice([2020, 2021, 2022, 2023])}-{random.randint(1,12):02d}-{random.randint(1,28):02d}",
            # Wrong format
            lambda: f"{random.randint(1,28):02d}/{random.randint(1,12):02d}/{random.choice([2025, 2026])}",
            # Missing
            lambda: random.choice(["N/A", "", "UNKNOWN", "???"]),
        ]
        return random.choice(patterns)()


def _add_noise_to_text(text: str) -> str:
    """
    Add random noise to a text string for suspicious records.

    Noise types: extra spaces, case changes, character swaps, typos.

    Args:
        text: Original text.

    Returns:
        Noisy version of the text.
    """
    noise_type = random.choice(["extra_space", "case", "typo", "none", "none"])

    if noise_type == "extra_space":
        # Add random extra spaces
        words = text.split()
        idx = random.randint(0, max(0, len(words) - 1))
        words[idx] = "  " + words[idx] + " "
        return " ".join(words)
    elif noise_type == "case":
        # Random case changes
        return random.choice([text.upper(), text.lower(), text.swapcase()])
    elif noise_type == "typo":
        # Swap two adjacent characters
        if len(text) > 3:
            idx = random.randint(1, len(text) - 2)
            text_list = list(text)
            text_list[idx], text_list[idx + 1] = text_list[idx + 1], text_list[idx]
            return "".join(text_list)
    return text


# ==============================================================================
# Main Dataset Generator
# ==============================================================================

def generate_synthetic_dataset(
    n_records: int = 2000,
    genuine_ratio: float = 0.55,
    random_seed: int = 42,
    save_path: Optional[str] = None,
) -> pd.DataFrame:
    """
    Generate a synthetic dataset of drug records for classification.

    Creates a mix of genuine and suspicious drug records with realistic
    Nigerian pharmaceutical data. Suspicious records contain intentional
    anomalies: invalid NAFDAC numbers, unknown manufacturers, bad barcodes,
    missing values, duplicates, typos, and inconsistent formatting.

    Args:
        n_records: Total number of records to generate (default: 2000).
        genuine_ratio: Fraction of genuine records (default: 0.55).
        random_seed: Random seed for reproducibility (default: 42).
        save_path: File path to save CSV. If None, saves to data/synthetic_drugs.csv.

    Returns:
        pd.DataFrame with columns: DrugName, Manufacturer, NAFDAC_Number,
        Barcode, BatchNumber, ExpiryDate, DosageForm, Strength, PackageSize,
        Country, Label.

    Example:
        >>> df = generate_synthetic_dataset(n_records=100)
        >>> print(df.shape)
        (100, 11)
        >>> print(df['Label'].value_counts())
    """
    random.seed(random_seed)
    np.random.seed(random_seed)

    n_genuine = int(n_records * genuine_ratio)
    n_suspicious = n_records - n_genuine

    logger.info(f"Generating {n_records} records: {n_genuine} genuine, {n_suspicious} suspicious")

    records = []

    # ---- Generate Genuine Records ----
    for i in range(n_genuine):
        drug_name = random.choice(GENUINE_DRUG_NAMES)
        manufacturer = random.choice(GENUINE_MANUFACTURERS)
        nafdac = _generate_valid_nafdac(i)
        barcode = _generate_valid_barcode()
        batch = _generate_batch_number(genuine=True)
        expiry = _generate_expiry_date(genuine=True)
        dosage = random.choice(DOSAGE_FORMS)
        strength = random.choice(STRENGTHS)
        package = random.choice(PACKAGE_SIZES)
        country = "Nigeria"

        records.append({
            "DrugName": drug_name,
            "Manufacturer": manufacturer,
            "NAFDAC_Number": nafdac,
            "Barcode": barcode,
            "BatchNumber": batch,
            "ExpiryDate": expiry,
            "DosageForm": dosage,
            "Strength": strength,
            "PackageSize": package,
            "Country": country,
            "Label": "Genuine",
        })

    # ---- Generate Suspicious Records ----
    for i in range(n_suspicious):
        # Mix of fake and real drug names (with possible noise)
        if random.random() < 0.6:
            drug_name = _add_noise_to_text(random.choice(GENUINE_DRUG_NAMES))
        else:
            drug_name = random.choice([
                "Paracetmol", "Amoxicilin", "Metronidazol", "Ciprofloxacn",
                "Vitamin CC", "Panado", "Flagy", "Augmenti", "Lonart DS Extra",
                "Super Paracetamol", "Magic Cure Pill", "Instant Relief Caps",
                "Power Drug", "MegaVit Plus", "Total Cure Tablets",
            ])

        # Fake or real manufacturer (mostly fake)
        if random.random() < 0.7:
            manufacturer = random.choice(FAKE_MANUFACTURERS)
        else:
            manufacturer = _add_noise_to_text(random.choice(GENUINE_MANUFACTURERS))

        # Invalid NAFDAC (mostly) or noisy valid
        if random.random() < 0.75:
            nafdac = _generate_invalid_nafdac()
        else:
            nafdac = _add_noise_to_text(_generate_valid_nafdac(i))

        # Invalid barcode (mostly)
        if random.random() < 0.7:
            barcode = _generate_invalid_barcode()
        else:
            barcode = _generate_valid_barcode()

        batch = _generate_batch_number(genuine=False)
        expiry = _generate_expiry_date(genuine=False)
        dosage = _add_noise_to_text(random.choice(DOSAGE_FORMS))
        strength = random.choice(STRENGTHS + ["UNKNOWN", "N/A", "???"])
        package = random.choice(PACKAGE_SIZES + ["N/A", "1 pack", "BULK"])
        country = random.choice(COUNTRIES_SUSPICIOUS)

        records.append({
            "DrugName": drug_name,
            "Manufacturer": manufacturer,
            "NAFDAC_Number": nafdac,
            "Barcode": barcode,
            "BatchNumber": batch,
            "ExpiryDate": expiry,
            "DosageForm": dosage,
            "Strength": strength,
            "PackageSize": package,
            "Country": country,
            "Label": "Suspicious",
        })

    # Create DataFrame
    df = pd.DataFrame(records)

    # Shuffle the dataset
    df = df.sample(frac=1, random_state=random_seed).reset_index(drop=True)

    # ---- Introduce Missing Values (randomly) ----
    n_missing = int(n_records * 0.03)  # ~3% missing values
    for _ in range(n_missing):
        row_idx = random.randint(0, len(df) - 1)
        col = random.choice(["DrugName", "Manufacturer", "NAFDAC_Number",
                             "Barcode", "BatchNumber", "Strength"])
        df.at[row_idx, col] = np.nan

    # ---- Introduce Duplicates (~2%) ----
    n_duplicates = int(n_records * 0.02)
    if n_duplicates > 0:
        dup_indices = random.sample(range(len(df)), min(n_duplicates, len(df)))
        duplicates = df.iloc[dup_indices].copy()
        df = pd.concat([df, duplicates], ignore_index=True)

    logger.info(f"Dataset generated: {df.shape[0]} rows, {df.shape[1]} columns")
    logger.info(f"Label distribution:\n{df['Label'].value_counts().to_string()}")

    # Save to CSV
    if save_path is None:
        save_path = str(DATA_DIR / "synthetic_drugs.csv")

    df.to_csv(save_path, index=False)
    logger.info(f"Dataset saved to: {save_path}")

    return df


# ==============================================================================
# I/O Helpers
# ==============================================================================

def load_dataset(filepath: Optional[str] = None) -> pd.DataFrame:
    """
    Load a dataset from CSV file.

    Args:
        filepath: Path to CSV file. Defaults to data/synthetic_drugs.csv.

    Returns:
        pd.DataFrame with the loaded data.

    Raises:
        FileNotFoundError: If the file does not exist.
    """
    if filepath is None:
        filepath = str(DATA_DIR / "synthetic_drugs.csv")

    if not os.path.exists(filepath):
        raise FileNotFoundError(
            f"Dataset not found at '{filepath}'. "
            "Run generate_synthetic_dataset() first."
        )

    df = pd.read_csv(filepath)
    logger.info(f"Loaded dataset: {df.shape[0]} rows, {df.shape[1]} columns from {filepath}")
    return df


def save_dataset(df: pd.DataFrame, filename: str = "drugs.csv") -> str:
    """
    Save a DataFrame to the data directory.

    Args:
        df: DataFrame to save.
        filename: Output filename (default: drugs.csv).

    Returns:
        The full path where the file was saved.
    """
    filepath = str(DATA_DIR / filename)
    df.to_csv(filepath, index=False)
    logger.info(f"Dataset saved: {df.shape[0]} rows → {filepath}")
    return filepath


# ==============================================================================
# Known-Good Reference Lists (for the predictor's explanation engine)
# ==============================================================================

KNOWN_MANUFACTURERS = set(m.lower().strip() for m in GENUINE_MANUFACTURERS)
KNOWN_DRUG_NAMES = set(d.lower().strip() for d in GENUINE_DRUG_NAMES)

# Valid NAFDAC pattern: Letter+Digit, dash, 4 digits (e.g., A4-7823)
NAFDAC_PATTERN = r"^[A-Z][0-9]-[0-9]{4}$"


# ==============================================================================
# Main — Generate dataset when run directly
# ==============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("  FakeDrugChecker — Synthetic Dataset Generator")
    print("=" * 60)
    df = generate_synthetic_dataset(n_records=2000, random_seed=42)
    print(f"\nDataset shape: {df.shape}")
    print(f"\nLabel distribution:\n{df['Label'].value_counts()}")
    print(f"\nFirst 5 rows:\n{df.head()}")
    print(f"\nSaved to: {DATA_DIR / 'synthetic_drugs.csv'}")
