"""
app.py — Streamlit Web Application for Fake Drug Checker
==========================================================

A modern, professional Streamlit UI with:
    - Drug input form with 8 fields
    - Barcode text input or image upload (with pyzbar decoding)
    - Prediction results with color-coded cards
    - Confidence meter and explanation
    - Prediction history and CSV export
    - Dataset visualizations
    - Dark mode support and sample inputs

Author: FakeDrugChecker Team
"""

import os
import sys
import io
import csv
import datetime
from pathlib import Path
from typing import Optional

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns

# ---------------------------------------------------------------------------
# Fix imports: add project root to sys.path
# ---------------------------------------------------------------------------
APP_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = APP_DIR.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.predictor import predict_drug, load_model_artifacts, clear_cache
from src.utils import (
    DATA_DIR, MODELS_DIR, SCREENSHOTS_DIR,
    GENUINE_DRUG_NAMES, GENUINE_MANUFACTURERS, DOSAGE_FORMS, STRENGTHS,
)


# ==============================================================================
# Page Configuration
# ==============================================================================

st.set_page_config(
    page_title="Fake Drug Checker — AI Drug Verification",
    page_icon="💊",
    layout="wide",
    initial_sidebar_state="expanded",
)


# ==============================================================================
# Custom CSS — Premium Dark Theme
# ==============================================================================

def inject_custom_css() -> None:
    """Inject custom CSS for a premium, modern look."""
    st.markdown("""
    <style>
    /* ---- Import Google Font ---- */
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');

    /* ---- Global Styles ---- */
    html, body, [class*="css"] {
        font-family: 'Inter', sans-serif;
    }

    /* ---- Header Banner ---- */
    .main-header {
        background: linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%);
        padding: 2rem 2.5rem;
        border-radius: 16px;
        margin-bottom: 2rem;
        text-align: center;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        border: 1px solid rgba(255, 255, 255, 0.08);
    }
    .main-header h1 {
        color: #ffffff;
        font-size: 2.4rem;
        font-weight: 800;
        margin-bottom: 0.4rem;
        letter-spacing: -0.5px;
    }
    .main-header p {
        color: #94a3b8;
        font-size: 1.05rem;
        font-weight: 400;
    }

    /* ---- Result Cards ---- */
    .result-card {
        padding: 1.8rem 2rem;
        border-radius: 14px;
        margin: 1rem 0;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
        border-left: 5px solid;
    }
    .result-genuine {
        background: linear-gradient(135deg, #064e3b 0%, #065f46 100%);
        border-left-color: #10b981;
        color: #d1fae5;
    }
    .result-suspicious {
        background: linear-gradient(135deg, #7f1d1d 0%, #991b1b 100%);
        border-left-color: #ef4444;
        color: #fecaca;
    }
    .result-card h2 {
        font-size: 1.6rem;
        font-weight: 700;
        margin-bottom: 0.5rem;
    }
    .result-card .confidence {
        font-size: 2.2rem;
        font-weight: 800;
    }

    /* ---- Explanation Items ---- */
    .explanation-item {
        padding: 0.6rem 0;
        font-size: 0.95rem;
        border-bottom: 1px solid rgba(255, 255, 255, 0.06);
    }

    /* ---- Metric Cards ---- */
    .metric-card {
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        padding: 1.2rem 1.5rem;
        border-radius: 12px;
        text-align: center;
        box-shadow: 0 2px 12px rgba(0, 0, 0, 0.15);
        border: 1px solid rgba(255, 255, 255, 0.06);
    }
    .metric-card h3 {
        color: #94a3b8;
        font-size: 0.85rem;
        font-weight: 500;
        text-transform: uppercase;
        letter-spacing: 1px;
        margin-bottom: 0.3rem;
    }
    .metric-card .value {
        color: #f1f5f9;
        font-size: 1.8rem;
        font-weight: 700;
    }

    /* ---- Sidebar Styling ---- */
    [data-testid="stSidebar"] {
        background: linear-gradient(180deg, #0f172a 0%, #1e293b 100%);
    }
    [data-testid="stSidebar"] .stMarkdown h1,
    [data-testid="stSidebar"] .stMarkdown h2,
    [data-testid="stSidebar"] .stMarkdown h3 {
        color: #e2e8f0;
    }

    /* ---- Button Styling ---- */
    .stButton > button {
        border-radius: 10px;
        font-weight: 600;
        padding: 0.6rem 2rem;
        font-size: 1rem;
        transition: all 0.3s ease;
        border: none;
    }
    .stButton > button:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 20px rgba(0, 0, 0, 0.25);
    }

    /* ---- Recommendation Box ---- */
    .recommendation-box {
        background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
        padding: 1.3rem 1.6rem;
        border-radius: 12px;
        margin-top: 1rem;
        border: 1px solid rgba(255, 255, 255, 0.08);
        font-size: 0.95rem;
        color: #cbd5e1;
        line-height: 1.6;
    }

    /* ---- Hide Streamlit branding ---- */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    </style>
    """, unsafe_allow_html=True)


# ==============================================================================
# Sidebar
# ==============================================================================

def render_sidebar() -> None:
    """Render the sidebar with About, Instructions, and Stats."""
    with st.sidebar:
        st.markdown("# 💊 Fake Drug Checker")
        st.markdown("---")

        # About
        st.markdown("### 📋 About")
        st.markdown(
            "This AI-powered tool uses Machine Learning to predict whether "
            "a drug record appears **Genuine** or **Suspicious** based on "
            "product information such as drug name, manufacturer, NAFDAC "
            "number, barcode, and more."
        )
        st.markdown(
            "> ⚠️ This tool is for **educational purposes**. Always verify "
            "drugs with [NAFDAC](https://www.nafdac.gov.ng/) and consult a pharmacist."
        )

        st.markdown("---")

        # Instructions
        st.markdown("### 📖 How to Use")
        st.markdown("""
        1. Enter the drug details in the form
        2. You can type or upload a barcode image
        3. Click **🔍 Check Drug**
        4. View the prediction and explanation
        5. Export results to CSV if needed
        """)

        st.markdown("---")

        # Model Info
        st.markdown("### 🤖 Model Info")
        try:
            artifacts = load_model_artifacts()
            model = artifacts["model"]
            model_name = type(model).__name__
            # Handle CalibratedClassifierCV wrapper
            if hasattr(model, "estimator"):
                model_name = f"Calibrated {type(model.estimator).__name__}"
            elif hasattr(model, "calibrated_classifiers_"):
                base = model.calibrated_classifiers_[0].estimator
                model_name = f"Calibrated {type(base).__name__}"

            st.markdown(f"**Model:** {model_name}")
            st.success("✅ Model loaded successfully")
        except FileNotFoundError:
            st.error("❌ Model not found. Please train the model first.")

        st.markdown("---")

        # Dataset Stats
        st.markdown("### 📊 Dataset Statistics")
        try:
            df = pd.read_csv(str(DATA_DIR / "drugs.csv"))
            col1, col2 = st.columns(2)
            with col1:
                st.metric("Total Records", f"{len(df):,}")
            with col2:
                st.metric("Features", f"{df.shape[1]}")

            genuine = len(df[df["Label"] == "genuine"]) if "genuine" in df["Label"].values else len(df[df["Label"] == "Genuine"])
            suspicious = len(df) - genuine
            st.metric("Genuine", f"{genuine:,}")
            st.metric("Suspicious", f"{suspicious:,}")
        except Exception:
            st.info("Dataset stats will appear after training.")

        st.markdown("---")
        st.markdown(
            "<div style='text-align: center; color: #64748b; font-size: 0.8rem;'>"
            "Built with ❤️ using Streamlit & Scikit-Learn<br>"
            "© 2026 FakeDrugChecker"
            "</div>",
            unsafe_allow_html=True,
        )


# ==============================================================================
# Barcode Decoder
# ==============================================================================

def decode_barcode_image(uploaded_file) -> Optional[str]:
    """
    Attempt to decode a barcode from an uploaded image.

    Uses OpenCV + pyzbar if available, otherwise returns None.

    Args:
        uploaded_file: Streamlit UploadedFile object.

    Returns:
        Decoded barcode string, or None if decoding fails.
    """
    try:
        import cv2
        from pyzbar.pyzbar import decode as pyzbar_decode

        # Read image bytes
        file_bytes = np.asarray(bytearray(uploaded_file.read()), dtype=np.uint8)
        image = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

        if image is None:
            return None

        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Decode barcodes
        barcodes = pyzbar_decode(gray)

        if barcodes:
            return barcodes[0].data.decode("utf-8")
        else:
            return None

    except ImportError:
        st.warning(
            "📦 Barcode image decoding requires `opencv-python` and `pyzbar`. "
            "Install them with: `pip install opencv-python-headless pyzbar`"
        )
        return None
    except Exception as e:
        st.error(f"Error decoding barcode: {str(e)}")
        return None


# ==============================================================================
# Sample Inputs
# ==============================================================================

SAMPLE_GENUINE = {
    "drug_name": "Paracetamol",
    "manufacturer": "Emzor Pharmaceutical Industries",
    "nafdac_number": "A4-7823",
    "barcode": "6190012345670",
    "batch_number": "BN25-0042",
    "dosage_form": "Tablet",
    "strength": "500mg",
    "country": "Nigeria",
}

SAMPLE_SUSPICIOUS = {
    "drug_name": "Super Paracetmol",
    "manufacturer": "QuickCure Labs",
    "nafdac_number": "INVALID123",
    "barcode": "12345",
    "batch_number": "???",
    "dosage_form": "Tablet",
    "strength": "500mg",
    "country": "China",
}


# ==============================================================================
# Main Application
# ==============================================================================

def main() -> None:
    """Main Streamlit application entry point."""

    inject_custom_css()
    render_sidebar()

    # Initialize session state
    if "prediction_history" not in st.session_state:
        st.session_state.prediction_history = []
    if "sample_data" not in st.session_state:
        st.session_state.sample_data = {}

    # ---- Header ----
    st.markdown("""
    <div class="main-header">
        <h1>💊 Fake Drug Checker</h1>
        <p>AI-Powered Drug Verification System for Nigeria</p>
    </div>
    """, unsafe_allow_html=True)

    # ---- Tabs ----
    tab_check, tab_history, tab_viz = st.tabs([
        "🔍 Check Drug", "📜 Prediction History", "📊 Visualizations"
    ])

    # ==================================================================
    # TAB 1: Check Drug
    # ==================================================================
    with tab_check:
        # Sample input buttons
        st.markdown("#### Quick Fill with Sample Data")
        col_s1, col_s2, col_s3 = st.columns(3)

        with col_s1:
            if st.button("✅ Load Genuine Sample", use_container_width=True):
                st.session_state.sample_data = SAMPLE_GENUINE

        with col_s2:
            if st.button("🚩 Load Suspicious Sample", use_container_width=True):
                st.session_state.sample_data = SAMPLE_SUSPICIOUS

        with col_s3:
            if st.button("🔄 Clear Form", use_container_width=True):
                st.session_state.sample_data = {}

        st.markdown("---")

        # Get sample data if set
        sample = st.session_state.get("sample_data", {})

        # ---- Input Form ----
        st.markdown("#### 📝 Enter Drug Information")

        col1, col2 = st.columns(2)

        with col1:
            drug_name = st.text_input(
                "Drug Name *",
                value=sample.get("drug_name", ""),
                placeholder="e.g., Paracetamol, Amoxicillin",
                help="Enter the name printed on the drug package",
            )
            manufacturer = st.text_input(
                "Manufacturer *",
                value=sample.get("manufacturer", ""),
                placeholder="e.g., Emzor Pharmaceutical Industries",
                help="Enter the manufacturer's name from the package",
            )
            nafdac_number = st.text_input(
                "NAFDAC Number *",
                value=sample.get("nafdac_number", ""),
                placeholder="e.g., A4-7823",
                help="NAFDAC registration number (format: XX-XXXX)",
            )
            dosage_form = st.selectbox(
                "Dosage Form",
                options=[""] + DOSAGE_FORMS,
                index=DOSAGE_FORMS.index(sample.get("dosage_form", "")) + 1 if sample.get("dosage_form") in DOSAGE_FORMS else 0,
                help="Select the dosage form of the drug",
            )

        with col2:
            strength = st.text_input(
                "Strength",
                value=sample.get("strength", ""),
                placeholder="e.g., 500mg, 250mg/5ml",
                help="Drug strength/concentration",
            )
            batch_number = st.text_input(
                "Batch Number",
                value=sample.get("batch_number", ""),
                placeholder="e.g., BN25-0042",
                help="Batch or lot number from the package",
            )
            country = st.text_input(
                "Country of Origin",
                value=sample.get("country", ""),
                placeholder="e.g., Nigeria",
                help="Where was the drug manufactured?",
            )

            # Barcode section
            st.markdown("**Barcode**")
            barcode_method = st.radio(
                "How would you like to enter the barcode?",
                options=["Type manually", "Upload image"],
                horizontal=True,
                label_visibility="collapsed",
            )

        # Barcode input
        barcode = ""
        if barcode_method == "Type manually":
            barcode = st.text_input(
                "Barcode Number",
                value=sample.get("barcode", ""),
                placeholder="e.g., 6190012345670 (13 digits)",
                help="Enter the barcode number printed on the package",
            )
        else:
            uploaded_file = st.file_uploader(
                "Upload barcode image",
                type=["png", "jpg", "jpeg", "bmp"],
                help="Upload a clear photo of the barcode",
            )
            if uploaded_file is not None:
                st.image(uploaded_file, caption="Uploaded barcode image", width=300)
                decoded = decode_barcode_image(uploaded_file)
                if decoded:
                    barcode = decoded
                    st.success(f"✅ Barcode decoded: **{decoded}**")
                else:
                    st.warning(
                        "⚠️ Could not decode the barcode from this image. "
                        "Please try a clearer image or type the barcode manually."
                    )

        st.markdown("---")

        # ---- Action Buttons ----
        col_btn1, col_btn2 = st.columns([1, 1])

        with col_btn1:
            check_clicked = st.button(
                "🔍 Check Drug",
                type="primary",
                use_container_width=True,
            )

        with col_btn2:
            if st.button("🔄 Reset", use_container_width=True):
                st.session_state.sample_data = {}
                st.rerun()

        # ---- Prediction ----
        if check_clicked:
            if not drug_name and not manufacturer:
                st.warning("⚠️ Please enter at least a drug name or manufacturer.")
            else:
                with st.spinner("🔍 Analyzing drug record..."):
                    try:
                        result = predict_drug(
                            drug_name=drug_name,
                            manufacturer=manufacturer,
                            nafdac_number=nafdac_number,
                            barcode=barcode,
                            batch_number=batch_number,
                            dosage_form=dosage_form or "",
                            strength=strength,
                            country=country,
                        )

                        # Add to history
                        result["timestamp"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        st.session_state.prediction_history.append(result)

                        # Display results
                        _display_results(result)

                    except FileNotFoundError:
                        st.error(
                            "❌ Model not found! Please train the model first by running:\n\n"
                            "```bash\n"
                            "cd FakeDrugChecker\n"
                            "python -m src.train_model\n"
                            "```"
                        )
                    except Exception as e:
                        st.error(f"❌ An error occurred: {str(e)}")

    # ==================================================================
    # TAB 2: Prediction History
    # ==================================================================
    with tab_history:
        st.markdown("#### 📜 Prediction History")

        history = st.session_state.get("prediction_history", [])

        if not history:
            st.info("No predictions yet. Use the 'Check Drug' tab to analyze a drug.")
        else:
            st.markdown(f"**{len(history)} predictions recorded this session**")

            # Export button
            if st.button("📥 Export History to CSV"):
                csv_data = _history_to_csv(history)
                st.download_button(
                    label="⬇️ Download CSV",
                    data=csv_data,
                    file_name=f"prediction_history_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                )

            # Display history table
            history_rows = []
            for i, h in enumerate(reversed(history), 1):
                history_rows.append({
                    "#": i,
                    "Time": h.get("timestamp", "N/A"),
                    "Drug": h["input_data"]["DrugName"],
                    "Manufacturer": h["input_data"]["Manufacturer"],
                    "Prediction": h["prediction"],
                    "Confidence": h["confidence_percent"],
                })

            df_history = pd.DataFrame(history_rows)
            st.dataframe(
                df_history,
                use_container_width=True,
                hide_index=True,
                column_config={
                    "Prediction": st.column_config.TextColumn(
                        "Prediction",
                        help="Model prediction",
                    ),
                },
            )

    # ==================================================================
    # TAB 3: Visualizations
    # ==================================================================
    with tab_viz:
        st.markdown("#### 📊 Dataset & Model Visualizations")

        # Load saved charts if available
        screenshots_path = SCREENSHOTS_DIR

        viz_options = st.selectbox(
            "Select Visualization",
            [
                "Dataset Distribution",
                "Top Manufacturers",
                "Drug Frequency",
                "Model Comparison",
                "Confusion Matrix",
                "ROC Curve",
                "Feature Importance",
            ],
        )

        chart_map = {
            "Dataset Distribution": "dataset_distribution.png",
            "Top Manufacturers": "top_manufacturers.png",
            "Drug Frequency": "drug_frequency.png",
            "Model Comparison": "model_comparison.png",
            "Confusion Matrix": "confusion_matrix.png",
            "ROC Curve": "roc_curve.png",
            "Feature Importance": "feature_importance.png",
        }

        chart_file = screenshots_path / chart_map[viz_options]

        if chart_file.exists():
            st.image(str(chart_file), caption=viz_options, use_container_width=True)
        else:
            st.info(
                f"📊 '{viz_options}' chart not yet generated. "
                "Train the model to generate evaluation charts."
            )

            # Offer to generate live charts from data
            if st.button("Generate from Dataset"):
                try:
                    df = pd.read_csv(str(DATA_DIR / "drugs.csv"))
                    _generate_live_chart(viz_options, df)
                except FileNotFoundError:
                    st.warning("Dataset not found. Please generate and train first.")


# ==============================================================================
# Display Helpers
# ==============================================================================

def _display_results(result: dict) -> None:
    """Display prediction results with styled cards."""
    prediction = result["prediction"]
    confidence = result["confidence"]
    explanation = result["explanation"]
    recommendation = result["recommendation"]

    # Result card
    card_class = "result-genuine" if prediction == "Genuine" else "result-suspicious"
    icon = "✅" if prediction == "Genuine" else "🚨"

    st.markdown(f"""
    <div class="result-card {card_class}">
        <h2>{icon} Prediction: {prediction}</h2>
        <div class="confidence">Confidence: {result['confidence_percent']}</div>
    </div>
    """, unsafe_allow_html=True)

    # Confidence meter
    st.markdown("**Confidence Meter**")
    color = "green" if prediction == "Genuine" else "red"
    st.progress(confidence, text=f"{result['confidence_percent']} confidence")

    # Explanation
    st.markdown("**📋 Detailed Explanation**")
    for exp in explanation:
        st.markdown(f"""
        <div class="explanation-item">{exp}</div>
        """, unsafe_allow_html=True)

    # Recommendation
    st.markdown("**💡 Recommendation**")
    st.markdown(f"""
    <div class="recommendation-box">{recommendation}</div>
    """, unsafe_allow_html=True)

    # Prediction probability chart
    st.markdown("**📊 Prediction Probability**")
    fig, ax = plt.subplots(figsize=(6, 2.5))
    if prediction == "Genuine":
        probs = [confidence, 1 - confidence]
    else:
        probs = [1 - confidence, confidence]

    bars = ax.barh(
        ["Genuine", "Suspicious"], probs,
        color=["#10b981", "#ef4444"],
        height=0.5,
        edgecolor="white",
        linewidth=1,
    )
    ax.set_xlim(0, 1)
    ax.set_xlabel("Probability")
    ax.set_title("Prediction Probability Distribution", fontweight="bold")

    for bar, prob in zip(bars, probs):
        ax.text(
            bar.get_width() + 0.02, bar.get_y() + bar.get_height() / 2,
            f"{prob:.1%}", va="center", fontweight="bold", fontsize=11,
        )

    plt.tight_layout()
    st.pyplot(fig)
    plt.close(fig)


def _history_to_csv(history: list) -> str:
    """Convert prediction history to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "Timestamp", "DrugName", "Manufacturer", "NAFDAC_Number",
        "Barcode", "BatchNumber", "DosageForm", "Strength",
        "Country", "Prediction", "Confidence",
    ])
    for h in history:
        inp = h["input_data"]
        writer.writerow([
            h.get("timestamp", ""),
            inp["DrugName"], inp["Manufacturer"], inp["NAFDAC_Number"],
            inp["Barcode"], inp["BatchNumber"], inp["DosageForm"],
            inp["Strength"], inp["Country"],
            h["prediction"], h["confidence_percent"],
        ])
    return output.getvalue()


def _generate_live_chart(chart_name: str, df: pd.DataFrame) -> None:
    """Generate a chart on-the-fly from the dataset."""
    fig, ax = plt.subplots(figsize=(10, 6))

    if chart_name == "Dataset Distribution":
        label_col = "Label" if "Label" in df.columns else "label"
        counts = df[label_col].value_counts()
        counts.plot(kind="bar", ax=ax, color=["#10b981", "#ef4444"], edgecolor="white")
        ax.set_title("Dataset Distribution", fontweight="bold")
        ax.set_ylabel("Count")
        ax.tick_params(axis="x", rotation=0)

    elif chart_name == "Top Manufacturers":
        mfr_col = "Manufacturer" if "Manufacturer" in df.columns else "manufacturer"
        df[mfr_col].value_counts().head(15).plot(
            kind="barh", ax=ax, color=plt.cm.Set2(np.linspace(0, 1, 15))
        )
        ax.set_title("Top 15 Manufacturers", fontweight="bold")
        ax.invert_yaxis()

    elif chart_name == "Drug Frequency":
        drug_col = "DrugName" if "DrugName" in df.columns else "drugname"
        df[drug_col].value_counts().head(15).plot(
            kind="barh", ax=ax, color=plt.cm.Paired(np.linspace(0, 1, 15))
        )
        ax.set_title("Top 15 Drug Names", fontweight="bold")
        ax.invert_yaxis()

    plt.tight_layout()
    st.pyplot(fig)
    plt.close(fig)


# ==============================================================================
# Entry Point
# ==============================================================================

if __name__ == "__main__":
    main()
