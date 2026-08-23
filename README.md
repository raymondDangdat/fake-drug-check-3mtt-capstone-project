# 💊 Fake Drug Checker — AI Drug Verification System

<p align="center">
  <img src="screenshots/model_comparison.png" alt="Model Comparison" width="700"/>
</p>

> An AI-powered Machine Learning tool that predicts whether a drug record appears **Genuine** or **Suspicious** based on product information — with explainable predictions.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Problem Statement](#-problem-statement)
- [Objectives](#-objectives)
- [Features](#-features)
- [Technologies](#-technologies)
- [Installation](#-installation)
- [Dataset](#-dataset)
- [Training the Model](#-training-the-model)
- [Evaluation](#-evaluation)
- [Running the Application](#-running-the-application)
- [Testing Predictions](#-testing-predictions)
- [Screenshots](#-screenshots)
- [Future Improvements](#-future-improvements)
- [License](#-license)
- [Author](#-author)

---

## 🔍 Project Overview

Counterfeit drugs are a serious public health challenge in Nigeria and across the developing world. Many fake drugs imitate genuine products by using fake NAFDAC registration numbers, incorrect manufacturers, invalid barcodes, or altered product information.

**Fake Drug Checker** is a Machine Learning classifier that predicts whether a drug record appears **Genuine** or **Suspicious** based on product information. The system provides explainable predictions — telling you *why* a drug was flagged.

> ⚠️ **Disclaimer**: This tool is for **educational and research purposes only**. Always verify drugs with [NAFDAC](https://www.nafdac.gov.ng/) and consult a licensed pharmacist.

---

## 🎯 Problem Statement

Nigeria's pharmaceutical market is plagued by counterfeit drugs that pose severe health risks. Manual verification is slow and inaccessible to most citizens. There is a need for an automated, intelligent system that can quickly flag suspicious drug records based on available product information.

---

## 📌 Objectives

1. Build a **synthetic dataset** of realistic drug records (genuine and suspicious)
2. Train **multiple ML classifiers** to detect suspicious drug records
3. Provide **explainable predictions** with confidence scores
4. Deploy an **interactive web application** using Streamlit
5. Support **barcode scanning** from images

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🤖 ML Classification | 4 models compared; best auto-selected by F1 Score |
| 📊 Explainable AI | Rule-based explanation engine explains every prediction |
| 💊 Drug Verification | Input drug details and get instant verdict |
| 📷 Barcode Scanning | Upload barcode image or type manually |
| 📈 Visualizations | Confusion matrix, ROC curve, feature importance, and more |
| 📜 Prediction History | Track all predictions with CSV export |
| 🎨 Modern UI | Premium dark-themed Streamlit interface |
| 🔢 Confidence Score | Probability-based confidence meter |
| 📋 Sample Inputs | Pre-filled genuine and suspicious examples |

---

## 🛠️ Technologies

| Technology | Purpose |
|-----------|---------|
| Python 3.12+ | Core programming language |
| Pandas | Data manipulation and analysis |
| NumPy | Numerical operations |
| Scikit-Learn | Machine Learning models and evaluation |
| Matplotlib | Data visualization |
| Seaborn | Statistical visualizations |
| Joblib | Model serialization |
| Streamlit | Web application framework |
| OpenCV | Barcode image processing (optional) |
| pyzbar | Barcode decoding (optional) |

---

## 🚀 Installation

### Prerequisites
- Python 3.12 or higher
- pip package manager

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/FakeDrugChecker.git
cd FakeDrugChecker

# 2. Create a virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate   # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. (Optional) Install barcode support
pip install opencv-python-headless pyzbar
```

---

## 📊 Dataset

The project uses a **synthetic dataset** of ~2,000 drug records generated with realistic Nigerian pharmaceutical data.

### Columns

| Column | Description |
|--------|-------------|
| DrugName | Name of the drug (e.g., Paracetamol) |
| Manufacturer | Pharmaceutical company name |
| NAFDAC_Number | NAFDAC registration number |
| Barcode | Product barcode (EAN-13) |
| BatchNumber | Manufacturing batch number |
| ExpiryDate | Drug expiry date |
| DosageForm | Form (Tablet, Capsule, Syrup, etc.) |
| Strength | Drug strength (e.g., 500mg) |
| PackageSize | Package size description |
| Country | Country of origin |
| Label | **Genuine** or **Suspicious** |

### Generate the Dataset

```bash
python -m src.utils
```

This creates `data/synthetic_drugs.csv` with ~2,000 records.

---

## 🧠 Training the Model

```bash
python -m src.train_model
```

This will:
1. Load/generate the synthetic dataset
2. Clean and preprocess the data
3. Create TF-IDF features
4. Train 4 models (Logistic Regression, Naive Bayes, Linear SVC, Random Forest)
5. Compare models by F1 Score
6. Save the best model to `models/`

### Models Compared

| Model | Why Include |
|-------|------------|
| Logistic Regression | Strong baseline, interpretable |
| Multinomial Naive Bayes | Excellent for text classification |
| Linear SVC | Strong for high-dimensional text data |
| Random Forest | Captures non-linear patterns |

---

## 📈 Evaluation

```bash
python -m src.evaluate
```

### Metrics Computed
- **Accuracy**: Overall correctness
- **Precision**: How many flagged drugs are truly suspicious
- **Recall**: How many suspicious drugs are correctly identified
- **F1 Score**: Harmonic mean of precision and recall
- **Confusion Matrix**: Visualization of prediction errors
- **ROC Curve**: Trade-off between true/false positive rates
- **Cross-Validation**: 5-fold CV for robustness

All evaluation charts are saved to the `screenshots/` directory.

---

## 🖥️ Running the Application

```bash
# From the project root directory
streamlit run app/app.py
```

The application will open at `http://localhost:8501`.

### Application Features
- **Input Form**: Enter drug details across 8 fields
- **Barcode Support**: Type or upload barcode image
- **Results Card**: Color-coded prediction with confidence meter
- **Explanation**: Detailed reasons for the prediction
- **History Tab**: View and export past predictions
- **Visualizations Tab**: Interactive dataset and model charts

---

## 🧪 Testing Predictions

### Via Python
```python
from src.predictor import predict_drug

result = predict_drug(
    drug_name="Paracetamol",
    manufacturer="Emzor Pharmaceutical Industries",
    nafdac_number="A4-7823",
    barcode="6190012345670",
    batch_number="BN25-0042",
    dosage_form="Tablet",
    strength="500mg",
    country="Nigeria",
)

print(f"Prediction:  {result['prediction']}")
print(f"Confidence:  {result['confidence_percent']}")
for exp in result['explanation']:
    print(f"  {exp}")
```

### Via Streamlit App
1. Open the app (`streamlit run app/app.py`)
2. Click "Load Genuine Sample" or "Load Suspicious Sample"
3. Click "🔍 Check Drug"
4. View results

---

## 📸 Screenshots

| Screenshot | Description |
|-----------|-------------|
| `screenshots/dataset_distribution.png` | Label distribution chart |
| `screenshots/top_manufacturers.png` | Most frequent manufacturers |
| `screenshots/drug_frequency.png` | Most common drug names |
| `screenshots/model_comparison.png` | Model comparison bar chart |
| `screenshots/confusion_matrix.png` | Confusion matrix heatmap |
| `screenshots/roc_curve.png` | ROC curve with AUC |
| `screenshots/feature_importance.png` | Top feature importances |

---

## 🔮 Future Improvements

1. **Real NAFDAC API Integration** — Verify against official NAFDAC database
2. **Deep Learning Models** — BERT/DistilBERT for text classification
3. **Mobile Application** — React Native or Flutter mobile app
4. **OCR Integration** — Extract drug info from package photos
5. **Database Backend** — Store predictions with user accounts
6. **Multi-language Support** — Hausa, Yoruba, Igbo translations
7. **SMS Verification** — USSD/SMS-based drug checking for feature phones
8. **Crowd-sourced Reports** — Community-driven fake drug reporting

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## 👤 Author

**FakeDrugChecker Team**

- 🎓 Capstone Project — 3MTT Programme
- 📧 Contact: [your-email@example.com]
- 🔗 GitHub: [github.com/yourusername](https://github.com/yourusername)

---

<p align="center">
  <em>Built with ❤️ for a safer Nigeria</em>
</p>
# fake-drug-check-3mtt-capstone-project
