# 🎬 Fake Drug Checker — Demo Video Script

## Duration: ~5 minutes

---

## Scene 1: Introduction (30 seconds)

**[Screen: Title Slide / README]**

> "Welcome to the Fake Drug Checker — an AI-powered drug verification system built with Machine Learning. This project addresses the critical issue of counterfeit drugs in Nigeria by using text classification to predict whether a drug record appears Genuine or Suspicious."

**[Talking Points]**
- Counterfeit drugs are a public health crisis
- This project uses ML to flag suspicious drug records
- Built with Python, Scikit-Learn, and Streamlit

---

## Scene 2: Project Structure (30 seconds)

**[Screen: File explorer showing project folder]**

> "Here's the project structure. We have a `data/` folder with our synthetic dataset, `src/` with all the ML modules, `models/` where trained models are saved, and `app/` with our Streamlit web application."

**[Show folder structure in terminal]**
```bash
tree FakeDrugChecker/ -L 2
```

---

## Scene 3: Dataset (45 seconds)

**[Screen: Terminal / Jupyter Notebook]**

> "Let's look at our dataset. We generated 2,000 synthetic drug records with realistic Nigerian pharmaceutical data."

**[Run in terminal or notebook]**
```python
import pandas as pd
df = pd.read_csv("data/synthetic_drugs.csv")
print(df.shape)
print(df.head())
print(df['Label'].value_counts())
```

**[Talking Points]**
- 11 columns including DrugName, Manufacturer, NAFDAC Number, Barcode
- ~55% Genuine, ~45% Suspicious
- Suspicious records have invalid NAFDAC numbers, unknown manufacturers, bad barcodes
- Noise, typos, missing values, and duplicates introduced for realism

---

## Scene 4: Training (45 seconds)

**[Screen: Terminal]**

> "Now let's train our models. We compare four classifiers: Logistic Regression, Naive Bayes, Linear SVC, and Random Forest."

**[Run]**
```bash
python -m src.train_model
```

**[Talking Points]**
- TF-IDF vectorization on combined text features
- 80/20 train/test split with stratification
- 5-fold cross-validation
- Best model automatically selected by F1 Score
- Model, vectorizer, and label encoder saved to `models/`

---

## Scene 5: Evaluation (45 seconds)

**[Screen: Charts from screenshots/]**

> "Let's look at our evaluation results."

**[Show screenshots one by one]**
1. **Model Comparison** — bar chart showing all 4 models across metrics
2. **Confusion Matrix** — heatmap of predictions vs actual
3. **ROC Curve** — AUC showing model discrimination ability
4. **Feature Importance** — which features matter most

**[Talking Points]**
- High F1 Score demonstrates strong classification
- Confusion matrix shows few misclassifications
- ROC AUC near 1.0 indicates excellent performance
- Top features include manufacturer names, NAFDAC patterns

---

## Scene 6: Streamlit Application (90 seconds)

**[Screen: Browser with Streamlit app]**

> "Now let's launch our web application."

**[Run]**
```bash
streamlit run app/app.py
```

### Demo 1: Genuine Drug
**[Click "Load Genuine Sample" → Click "Check Drug"]**

> "First, let's test with a genuine drug — Paracetamol from Emzor Pharmaceutical Industries with a valid NAFDAC number. The model correctly identifies it as Genuine with high confidence. Notice the green result card and the detailed explanation."

### Demo 2: Suspicious Drug
**[Click "Load Suspicious Sample" → Click "Check Drug"]**

> "Now let's try a suspicious drug — 'Super Paracetmol' from 'QuickCure Labs' with an invalid NAFDAC number and short barcode. The model flags it as Suspicious. The explanation highlights: unknown manufacturer, invalid NAFDAC pattern, and incorrect barcode length."

### Demo 3: Manual Input
**[Type custom drug details → Click "Check Drug"]**

> "You can also type in any drug details manually. Let me enter a drug I'm curious about..."

### Demo 4: Features Tour
**[Show tabs]**

> "The app also includes a Prediction History tab where you can track and export past predictions as CSV, and a Visualizations tab with dataset and model charts."

---

## Scene 7: Conclusion (30 seconds)

**[Screen: README or title slide]**

> "In summary, the Fake Drug Checker demonstrates how Machine Learning can be applied to a real-world public health problem. The system classifies drug records, explains its predictions, and provides actionable recommendations — all through an intuitive web interface."

**[Talking Points]**
- ML approach to drug verification
- Explainable predictions build trust
- Future work: NAFDAC API integration, mobile app, deep learning
- Open source and ready for deployment

> "Thank you for watching. The full source code is available on GitHub."

---

## 📝 Recording Tips

1. **Screen resolution**: Use 1920×1080 for crisp recording
2. **Font size**: Increase terminal/editor font to 16-18pt
3. **Browser zoom**: Set to 110% for Streamlit app
4. **Speed**: Speak clearly and pause at key results
5. **Mouse**: Move deliberately, circle important elements
6. **Software**: Use OBS Studio, Loom, or QuickTime for recording
