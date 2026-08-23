"""
app.py — Streamlit Web Application for Fake Drug Checker
==========================================================

A modern, clinical, human-centered Nigerian healthcare web portal for:
    - Drug verification with 8 clinical fields
    - Barcode manual input or image upload (with pyzbar decoding)
    - Diagnostic risk reports with clinical verdict cards
    - Confidence meter, findings breakdown, and actionable guidance
    - Verification history and CSV export
    - Dataset and model performance visualizations
    - Official NAFDAC regulatory compliance guide

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
    page_title="FakeDrugChecker — Nigeria Medication Authenticity Portal",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded",
)


# ==============================================================================
# Custom CSS — Clean Clinical Healthcare Theme
# ==============================================================================

def inject_custom_css() -> None:
    """Inject clean clinical CSS matching the Flutter design system."""
    st.markdown("""
    <style>
    /* ---- Import Google Fonts ---- */
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap');

    /* ---- Global Typography & Background ---- */
    html, body, [class*="css"] {
        font-family: 'Plus Jakarta Sans', 'Inter', -apple-system, sans-serif;
        color: #0F172A;
    }
    .stApp {
        background-color: #F8FAFC;
    }

    /* ---- Clinical Header Banner ---- */
    .clinical-header {
        background: linear-gradient(135deg, #0B6B48 0%, #064E35 100%);
        padding: 2.2rem 2.5rem;
        border-radius: 16px;
        margin-bottom: 2rem;
        color: #ffffff;
        box-shadow: 0 10px 25px -5px rgba(11, 107, 72, 0.2);
    }
    .clinical-header .badge {
        display: inline-block;
        background: rgba(255, 255, 255, 0.18);
        color: #ffffff;
        font-size: 0.75rem;
        font-weight: 700;
        padding: 0.25rem 0.6rem;
        border-radius: 9999px;
        margin-bottom: 0.8rem;
        letter-spacing: 0.5px;
        text-transform: uppercase;
    }
    .clinical-header h1 {
        color: #ffffff !important;
        font-size: 2.2rem;
        font-weight: 800;
        margin: 0 0 0.4rem 0;
        letter-spacing: -0.5px;
    }
    .clinical-header p {
        color: #E2E8F0;
        font-size: 1.05rem;
        margin: 0;
        font-weight: 400;
    }

    /* ---- Section Cards ---- */
    .form-section-card {
        background-color: #ffffff;
        border: 1px solid #E2E8F0;
        border-radius: 14px;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
    }
    .section-title {
        font-size: 1.1rem;
        font-weight: 700;
        color: #0F172A;
        margin-bottom: 0.2rem;
    }
    .section-subtitle {
        font-size: 0.85rem;
        color: #64748B;
        margin-bottom: 1rem;
    }

    /* ---- Result Cards ---- */
    .result-card-genuine {
        background-color: #ECFDF5;
        border: 1.5px solid #A7F3D0;
        border-left: 6px solid #059669;
        border-radius: 14px;
        padding: 1.5rem 1.8rem;
        margin: 1.2rem 0;
    }
    .result-card-suspicious {
        background-color: #FFF1F2;
        border: 1.5px solid #FECDD3;
        border-left: 6px solid #DC2626;
        border-radius: 14px;
        padding: 1.5rem 1.8rem;
        margin: 1.2rem 0;
    }
    .result-card-genuine h2 {
        color: #065F46 !important;
        font-size: 1.45rem;
        font-weight: 700;
        margin: 0 0 0.3rem 0;
    }
    .result-card-suspicious h2 {
        color: #991B1B !important;
        font-size: 1.45rem;
        font-weight: 700;
        margin: 0 0 0.3rem 0;
    }

    /* ---- Diagnostic Finding Item ---- */
    .finding-item {
        background-color: #F8FAFC;
        border: 1px solid #E2E8F0;
        border-radius: 8px;
        padding: 0.75rem 1rem;
        margin-bottom: 0.5rem;
        font-size: 0.92rem;
        color: #334155;
    }

    /* ---- Clinical Guidance Box ---- */
    .guidance-box {
        background-color: #F0F9FF;
        border: 1px solid #BAE6FD;
        border-radius: 12px;
        padding: 1.2rem 1.5rem;
        margin-top: 1rem;
        color: #0C4A6E;
        font-size: 0.95rem;
        line-height: 1.55;
    }

    /* ---- Regulatory Notice Box ---- */
    .disclaimer-box {
        background-color: #FFFBEB;
        border: 1px solid #FDE68A;
        border-radius: 12px;
        padding: 1.1rem 1.4rem;
        margin: 1.5rem 0;
        color: #78350F;
        font-size: 0.88rem;
        line-height: 1.5;
    }

    /* ---- Button Styling ---- */
    .stButton > button {
        border-radius: 10px;
        font-weight: 600;
        padding: 0.65rem 1.8rem;
        font-size: 0.95rem;
        transition: all 0.2s ease;
    }
    .stButton > button[kind="primary"] {
        background-color: #0B6B48 !important;
        border-color: #0B6B48 !important;
        color: #ffffff !important;
    }
    .stButton > button[kind="primary"]:hover {
        background-color: #064E35 !important;
        border-color: #064E35 !important;
    }

    /* ---- Sidebar Styling ---- */
    [data-testid="stSidebar"] {
        background-color: #FFFFFF;
        border-right: 1px solid #E2E8F0;
    }

    /* ---- Hide Streamlit Branding ---- */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    </style>
    """, unsafe_allow_html=True)


# ==============================================================================
# Sidebar
# ==============================================================================

def render_sidebar() -> None:
    """Render clinical sidebar with project overview and NAFDAC guidelines."""
    with st.sidebar:
        st.markdown("### 🛡️ FakeDrugChecker NG")
        st.caption("Medication Authenticity & Risk Verification Portal")
        st.markdown("---")

        # About
        st.markdown("#### 📋 3MTT Capstone Project")
        st.markdown(
            "FakeDrugChecker uses machine learning pattern recognition to cross-reference "
            "NAFDAC registration schemas, EAN-13 barcodes, registered manufacturers, "
            "and formulation strengths to identify counterfeit pharmaceutical risks."
        )

        st.markdown("---")

        # Official Verification Advice
        st.markdown("#### 🔒 NAFDAC Verification Tips")
        st.markdown("""
        - **MAS Scratch & SMS**: Scratch the silver panel on anti-malarials and SMS the PIN to **38353** or **2873**.
        - **Check Numbering**: Valid NAFDAC formats follow standard schemas such as `A4-XXXX` or `04-XXXX`.
        - **Inspect Seals**: Legitimate products have crisp packaging, intact tamper seals, and matching batch numbers across carton and blister foil.
        - **Licensed Premises**: Always purchase medications from PCN-registered community pharmacies.
        """)

        st.markdown("---")

        # Model Info
        st.markdown("#### 🤖 Model Status")
        try:
            artifacts = load_model_artifacts()
            model = artifacts["model"]
            model_name = type(model).__name__
            if hasattr(model, "estimator"):
                model_name = f"Calibrated {type(model.estimator).__name__}"
            elif hasattr(model, "calibrated_classifiers_"):
                base = model.calibrated_classifiers_[0].estimator
                model_name = f"Calibrated {type(base).__name__}"

            st.success(f"● Verification Engine Online\n({model_name})")
        except FileNotFoundError:
            st.error("❌ Model artifacts not loaded.")

        st.markdown("---")

        # Dataset Stats
        st.markdown("#### 📊 Reference Dataset")
        try:
            df = pd.read_csv(str(DATA_DIR / "drugs.csv"))
            col1, col2 = st.columns(2)
            with col1:
                st.metric("Total Records", f"{len(df):,}")
            with col2:
                st.metric("Features", f"{df.shape[1]}")

            genuine = len(df[df["Label"] == "genuine"]) if "genuine" in df["Label"].values else len(df[df["Label"] == "Genuine"])
            suspicious = len(df) - genuine
            st.metric("Genuine Reference", f"{genuine:,}")
            st.metric("Counterfeit Patterns", f"{suspicious:,}")
        except Exception:
            st.info("Dataset statistics loaded.")

        st.markdown("---")
        st.markdown(
            "<div style='text-align: center; color: #64748B; font-size: 0.78rem;'>"
            "3MTT Capstone Project • Nigeria<br>"
            "© 2026 FakeDrugChecker"
            "</div>",
            unsafe_allow_html=True,
        )


# ==============================================================================
# Barcode Decoder
# ==============================================================================

def decode_barcode_image(uploaded_file) -> Optional[str]:
    """Attempt to decode a barcode from an uploaded image."""
    try:
        import cv2
        from pyzbar.pyzbar import decode as pyzbar_decode

        file_bytes = np.asarray(bytearray(uploaded_file.read()), dtype=np.uint8)
        image = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

        if image is None:
            return None

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        barcodes = pyzbar_decode(gray)

        if barcodes:
            return barcodes[0].data.decode("utf-8")
        else:
            return None

    except ImportError:
        st.warning(
            "📦 Barcode image decoding requires `opencv-python` and `pyzbar`. "
            "Install with: `pip install opencv-python-headless pyzbar`"
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
    "drug_name": "Super Paracetmol Extra",
    "manufacturer": "QuickCure Labs International",
    "nafdac_number": "INVALID-999",
    "barcode": "12345678",
    "batch_number": "XYZ-UNKNOWN",
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

    if "prediction_history" not in st.session_state:
        st.session_state.prediction_history = []
    if "sample_data" not in st.session_state:
        st.session_state.sample_data = {}

    # ---- Clinical Header ----
    st.markdown("""
    <div class="clinical-header">
        <span class="badge">🇳🇬 Nigeria Medication Authenticity Portal</span>
        <h1>Verify Before You Trust</h1>
        <p>Check pharmaceutical packaging details, NAFDAC registration formats, and manufacturer records to detect counterfeit medication risks.</p>
    </div>
    """, unsafe_allow_html=True)

    # ---- Tabs ----
    tab_check, tab_history, tab_viz, tab_guide = st.tabs([
        "🔍 Verify Medicine", "📜 Verification History", "📊 Model Visualizations", "📖 NAFDAC Guide"
    ])

    # ==================================================================
    # TAB 1: Verify Medicine
    # ==================================================================
    with tab_check:
        # Quick sample presets
        st.markdown("##### ⚡ Quick Demonstration Presets")
        col_s1, col_s2, col_s3 = st.columns(3)

        with col_s1:
            if st.button("✅ Genuine Paracetamol Sample", use_container_width=True):
                st.session_state.sample_data = SAMPLE_GENUINE
                st.rerun()

        with col_s2:
            if st.button("⚠️ Suspicious / Counterfeit Sample", use_container_width=True):
                st.session_state.sample_data = SAMPLE_SUSPICIOUS
                st.rerun()

        with col_s3:
            if st.button("🔄 Clear Form", use_container_width=True):
                st.session_state.sample_data = {}
                st.rerun()

        st.markdown("<br>", unsafe_allow_html=True)
        sample = st.session_state.get("sample_data", {})

        # Form with 3 clinical sections
        with st.form("drug_check_form"):
            # Section 1: Medication Identity
            st.markdown("""
            <div class="form-section-card">
                <div class="section-title">1. Medication Identity</div>
                <div class="section-subtitle">Active product name, dosage form, and strength</div>
            </div>
            """, unsafe_allow_html=True)

            col1, col2, col3 = st.columns(3)
            with col1:
                drug_name = st.text_input(
                    "Medication Name *",
                    value=sample.get("drug_name", ""),
                    placeholder="e.g. Paracetamol or Coartem",
                    help="Name printed on outer carton or blister foil",
                )
            with col2:
                dosage_form = st.selectbox(
                    "Dosage Form",
                    options=[""] + DOSAGE_FORMS,
                    index=DOSAGE_FORMS.index(sample.get("dosage_form", "")) + 1 if sample.get("dosage_form") in DOSAGE_FORMS else 1,
                    help="Select formulation type",
                )
            with col3:
                strength = st.text_input(
                    "Strength / Concentration",
                    value=sample.get("strength", ""),
                    placeholder="e.g. 500mg or 20mg/120mg",
                    help="Active ingredient strength",
                )

            # Section 2: Identifiers & Packaging
            st.markdown("""
            <div class="form-section-card">
                <div class="section-title">2. Packaging & Registration Identifiers</div>
                <div class="section-subtitle">NAFDAC registration number, EAN-13 barcode, and batch code</div>
            </div>
            """, unsafe_allow_html=True)

            col4, col5, col6 = st.columns(3)
            with col4:
                nafdac_number = st.text_input(
                    "NAFDAC Registration Number",
                    value=sample.get("nafdac_number", ""),
                    placeholder="e.g. A4-7823 or 04-1234",
                    help="Found on the front or side of outer packaging",
                )
            with col5:
                barcode = st.text_input(
                    "Product Barcode (EAN-13)",
                    value=sample.get("barcode", ""),
                    placeholder="e.g. 6190012345670",
                    help="13-digit EAN barcode number",
                )
            with col6:
                batch_number = st.text_input(
                    "Batch / Lot Number",
                    value=sample.get("batch_number", ""),
                    placeholder="e.g. BN25-0042",
                    help="Embossed on blister pack or carton flap",
                )

            # Section 3: Manufacturer & Origin
            st.markdown("""
            <div class="form-section-card">
                <div class="section-title">3. Manufacturer & Country of Origin</div>
                <div class="section-subtitle">Entity responsible for production and distribution</div>
            </div>
            """, unsafe_allow_html=True)

            col7, col8 = st.columns(2)
            with col7:
                manufacturer = st.text_input(
                    "Manufacturer Entity *",
                    value=sample.get("manufacturer", ""),
                    placeholder="e.g. Emzor Pharmaceutical Industries",
                    help="Pharmaceutical manufacturer name",
                )
            with col8:
                country = st.text_input(
                    "Country of Origin",
                    value=sample.get("country", ""),
                    placeholder="e.g. Nigeria, India, China",
                    help="Country where medication was produced",
                )

            # Submit
            submit_clicked = st.form_submit_button(
                "🔍 Run AI Verification Check",
                type="primary",
                use_container_width=True,
            )

        # Image barcode upload option outside form
        with st.expander("📷 Or Upload Barcode Photo to Auto-Extract"):
            uploaded_file = st.file_uploader(
                "Upload a photo of the packaging barcode",
                type=["png", "jpg", "jpeg"],
            )
            if uploaded_file is not None:
                st.image(uploaded_file, caption="Uploaded image", width=260)
                decoded = decode_barcode_image(uploaded_file)
                if decoded:
                    st.success(f"✅ Barcode detected: **{decoded}**")
                    if st.button("Use this barcode in form"):
                        st.session_state.sample_data["barcode"] = decoded
                        st.rerun()
                else:
                    st.warning("Could not automatically decode barcode. Please type the digits into the form.")

        # ---- Process Submission ----
        if submit_clicked:
            if not drug_name.strip() and not manufacturer.strip():
                st.warning("⚠️ Please provide at least the medication name or manufacturer to perform verification.")
            else:
                with st.spinner("Analyzing medication patterns & NAFDAC registration schemas..."):
                    try:
                        result = predict_drug(
                            drug_name=drug_name.strip(),
                            manufacturer=manufacturer.strip(),
                            nafdac_number=nafdac_number.strip(),
                            barcode=barcode.strip(),
                            batch_number=batch_number.strip(),
                            dosage_form=dosage_form or "",
                            strength=strength.strip(),
                            country=country.strip(),
                        )

                        result["timestamp"] = datetime.datetime.now().strftime("%b %d, %Y • %I:%M %p")
                        st.session_state.prediction_history.append(result)

                        _display_results(result)

                    except FileNotFoundError:
                        st.error("❌ Verification model artifacts not found. Please ensure model training has been completed.")
                    except Exception as e:
                        st.error(f"❌ Verification failed: {str(e)}")

        # Regulatory Notice
        st.markdown("""
        <div class="disclaimer-box">
            <strong>🛡️ Regulatory Verification Notice</strong><br>
            This tool provides an AI-assisted risk assessment based on reference patterns.
            It does not replace official NAFDAC verification or professional clinical advice from a licensed pharmacist.
        </div>
        """, unsafe_allow_html=True)

    # ==================================================================
    # TAB 2: Verification History
    # ==================================================================
    with tab_history:
        st.markdown("#### 📜 Verification Archive")

        history = st.session_state.get("prediction_history", [])

        if not history:
            st.info("No verification checks performed in this session yet. Run a check to view history.")
        else:
            st.markdown(f"**{len(history)} verification checks saved in this session**")

            col_h1, col_h2 = st.columns([1, 4])
            with col_h1:
                csv_data = _history_to_csv(history)
                st.download_button(
                    label="📥 Download CSV Report",
                    data=csv_data,
                    file_name=f"verification_archive_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                    use_container_width=True,
                )

            history_rows = []
            for i, h in enumerate(reversed(history), 1):
                is_gen = h["prediction"] == "Genuine"
                history_rows.append({
                    "#": i,
                    "Timestamp": h.get("timestamp", "N/A"),
                    "Medication": h["input_data"]["DrugName"],
                    "Manufacturer": h["input_data"]["Manufacturer"],
                    "NAFDAC No.": h["input_data"]["NAFDAC_Number"],
                    "Risk Assessment": "Appears Consistent (Low Risk)" if is_gen else "Suspicious Indicators Detected",
                    "Confidence": h["confidence_percent"],
                })

            df_history = pd.DataFrame(history_rows)
            st.dataframe(
                df_history,
                use_container_width=True,
                hide_index=True,
            )

    # ==================================================================
    # TAB 3: Visualizations
    # ==================================================================
    with tab_viz:
        st.markdown("#### 📊 Model Performance & Dataset Metrics")

        screenshots_path = SCREENSHOTS_DIR
        viz_options = st.selectbox(
            "Select Evaluation Chart",
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
            st.info(f"📊 '{viz_options}' chart will appear once model training evaluation completes.")
            if st.button("Generate Chart from Dataset"):
                try:
                    df = pd.read_csv(str(DATA_DIR / "drugs.csv"))
                    _generate_live_chart(viz_options, df)
                except FileNotFoundError:
                    st.warning("Dataset not found.")

    # ==================================================================
    # TAB 4: NAFDAC Guide
    # ==================================================================
    with tab_guide:
        st.markdown("#### 🔒 Official NAFDAC Verification & Safe Medication Practices")
        st.markdown("""
        ### 1. Mobile Authentication Service (MAS)
        For anti-malarial and antibiotic medications, always check for the silver scratch panel:
        - Scratch the panel gently to reveal the unique PIN.
        - Send the PIN via free SMS to the designated shortcode (e.g. **38353** or **2873**).
        - Await an instant SMS confirmation from NAFDAC verifying product authenticity.

        ### 2. Physical Inspection Checklist
        - **Packaging Print Quality**: Genuine packaging has crisp typography, embossed batch numbers, and high-quality card stock.
        - **Matching Batch Numbers**: Confirm that the batch number on the outer carton matches the blister foil inside.
        - **Intact Seals**: Never accept medicine with broken tamper-evident seals or altered expiry dates.

        ### 3. Sourcing Medications Responsibly
        - Always purchase prescription drugs from registered community pharmacies supervised by licensed pharmacists under Pharmacists Council of Nigeria (PCN) regulations.
        - Avoid purchasing medicines from open street markets, buses, or unregistered hawkers.
        """)


# ==============================================================================
# Display Helpers
# ==============================================================================

def _display_results(result: dict) -> None:
    """Display clinical verification results."""
    prediction = result["prediction"]
    confidence = result["confidence"]
    explanation = result["explanation"]
    recommendation = result["recommendation"]
    is_genuine = prediction == "Genuine"

    verdict_title = "Appears Consistent (Low Risk)" if is_genuine else "Suspicious Indicators Detected"
    verdict_subtitle = (
        "The provided details align with standard pharmaceutical reference patterns."
        if is_genuine
        else "Discrepancies identified in format, manufacturer, or batch records."
    )
    card_class = "result-card-genuine" if is_genuine else "result-card-suspicious"
    icon = "✅" if is_genuine else "⚠️"

    st.markdown(f"""
    <div class="{card_class}">
        <h2>{icon} {verdict_title}</h2>
        <div style="font-size: 1rem; margin-bottom: 0.5rem;">{verdict_subtitle}</div>
        <div style="font-weight: 700; font-size: 1.15rem;">AI Model Confidence: {result['confidence_percent']}</div>
    </div>
    """, unsafe_allow_html=True)

    # Confidence progress bar
    st.progress(confidence, text=f"Model Confidence: {result['confidence_percent']}")

    # Diagnostic Findings
    st.markdown("##### 📋 Diagnostic Findings")
    for exp in explanation:
        clean_exp = exp.replace("✅", "").replace("⚠️", "").replace("🚩", "").replace("🔍", "").strip()
        is_pos = "✅" in exp or "match" in exp.lower() or "valid" in exp.lower()
        badge = "✅" if is_pos else "⚠️"
        st.markdown(f"""
        <div class="finding-item">{badge} {clean_exp}</div>
        """, unsafe_allow_html=True)

    # Clinical Guidance Box
    st.markdown("##### 💡 Clinical Guidance & Next Steps")
    st.markdown(f"""
    <div class="guidance-box">{recommendation}</div>
    """, unsafe_allow_html=True)

    # Submitted Parameters Summary Table
    st.markdown("##### 📦 Submitted Product Details")
    inp = result.get("input_data", {})
    summary_data = {
        "Parameter": [
            "Medication Name", "Manufacturer", "NAFDAC Number",
            "Barcode (EAN-13)", "Batch Number", "Dosage Form",
            "Strength", "Country of Origin",
        ],
        "Submitted Value": [
            inp.get("DrugName", "N/A"),
            inp.get("Manufacturer", "N/A"),
            inp.get("NAFDAC_Number", "N/A"),
            inp.get("Barcode", "N/A"),
            inp.get("BatchNumber", "N/A"),
            inp.get("DosageForm", "N/A"),
            inp.get("Strength", "N/A"),
            inp.get("Country", "N/A"),
        ],
    }
    st.dataframe(pd.DataFrame(summary_data), use_container_width=True, hide_index=True)


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
    """Generate a chart on-the-fly from dataset."""
    fig, ax = plt.subplots(figsize=(10, 5))

    if chart_name == "Dataset Distribution":
        label_col = "Label" if "Label" in df.columns else "label"
        counts = df[label_col].value_counts()
        counts.plot(kind="bar", ax=ax, color=["#059669", "#DC2626"], edgecolor="none")
        ax.set_title("Dataset Distribution (Genuine vs Suspicious)", fontweight="bold")
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
