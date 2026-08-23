"""
evaluate.py — Model Evaluation and Visualization
==================================================

This module computes evaluation metrics and generates plots:
    - Accuracy, Precision, Recall, F1 Score
    - Confusion Matrix heatmap
    - ROC Curve
    - Feature Importance (for applicable models)
    - Model Comparison bar chart
    - Classification Report

Author: FakeDrugChecker Team
"""

from typing import Dict, Any, Optional, List

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")  # Non-interactive backend for saving plots
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    confusion_matrix, classification_report, roc_curve, auc,
)
from sklearn.preprocessing import LabelEncoder

from src.utils import logger, SCREENSHOTS_DIR


# ==============================================================================
# Style Configuration
# ==============================================================================

# Set a professional plotting style
plt.rcParams.update({
    "figure.figsize": (10, 6),
    "font.size": 12,
    "axes.titlesize": 14,
    "axes.labelsize": 12,
    "xtick.labelsize": 10,
    "ytick.labelsize": 10,
    "legend.fontsize": 10,
    "figure.dpi": 150,
    "savefig.dpi": 150,
    "savefig.bbox": "tight",
})

# Color palette
COLORS = {
    "genuine": "#2ecc71",     # Green
    "suspicious": "#e74c3c",  # Red
    "primary": "#3498db",     # Blue
    "secondary": "#9b59b6",   # Purple
    "background": "#2c3e50",  # Dark blue-gray
}


# ==============================================================================
# Metrics Computation
# ==============================================================================

def compute_metrics(
    y_true: np.ndarray,
    y_pred: np.ndarray,
    label_encoder: Optional[LabelEncoder] = None,
) -> Dict[str, float]:
    """
    Compute all classification metrics.

    Args:
        y_true: True labels.
        y_pred: Predicted labels.
        label_encoder: Optional LabelEncoder for class names.

    Returns:
        Dict with accuracy, precision, recall, f1_score.
    """
    metrics = {
        "accuracy": accuracy_score(y_true, y_pred),
        "precision": precision_score(y_true, y_pred, average="weighted", zero_division=0),
        "recall": recall_score(y_true, y_pred, average="weighted", zero_division=0),
        "f1_score": f1_score(y_true, y_pred, average="weighted", zero_division=0),
    }

    logger.info("Classification Metrics:")
    for name, value in metrics.items():
        logger.info(f"  {name.capitalize():12s}: {value:.4f}")

    return metrics


def generate_classification_report(
    y_true: np.ndarray,
    y_pred: np.ndarray,
    label_encoder: Optional[LabelEncoder] = None,
) -> str:
    """
    Generate a detailed classification report.

    Args:
        y_true: True labels.
        y_pred: Predicted labels.
        label_encoder: Optional LabelEncoder for class names.

    Returns:
        Classification report as a formatted string.
    """
    target_names = None
    if label_encoder is not None:
        target_names = list(label_encoder.classes_)

    report = classification_report(
        y_true, y_pred,
        target_names=target_names,
        zero_division=0,
    )

    logger.info(f"\nClassification Report:\n{report}")
    return report


# ==============================================================================
# Visualization Functions
# ==============================================================================

def plot_confusion_matrix(
    y_true: np.ndarray,
    y_pred: np.ndarray,
    label_encoder: Optional[LabelEncoder] = None,
    save: bool = True,
) -> plt.Figure:
    """
    Plot and optionally save a confusion matrix heatmap.

    Args:
        y_true: True labels.
        y_pred: Predicted labels.
        label_encoder: Optional LabelEncoder for axis labels.
        save: If True, saves the plot to screenshots/.

    Returns:
        matplotlib Figure object.
    """
    cm = confusion_matrix(y_true, y_pred)
    labels = list(label_encoder.classes_) if label_encoder else ["Class 0", "Class 1"]

    fig, ax = plt.subplots(figsize=(8, 6))
    sns.heatmap(
        cm, annot=True, fmt="d", cmap="Blues",
        xticklabels=labels, yticklabels=labels,
        linewidths=0.5, linecolor="gray",
        annot_kws={"size": 16, "weight": "bold"},
        ax=ax,
    )
    ax.set_title("Confusion Matrix", fontsize=16, fontweight="bold", pad=15)
    ax.set_xlabel("Predicted Label", fontsize=13)
    ax.set_ylabel("True Label", fontsize=13)

    plt.tight_layout()

    if save:
        path = str(SCREENSHOTS_DIR / "confusion_matrix.png")
        fig.savefig(path)
        logger.info(f"Confusion matrix saved: {path}")

    return fig


def plot_roc_curve(
    y_true: np.ndarray,
    y_proba: np.ndarray,
    label_encoder: Optional[LabelEncoder] = None,
    save: bool = True,
) -> plt.Figure:
    """
    Plot and optionally save an ROC curve.

    Args:
        y_true: True labels (binary).
        y_proba: Predicted probabilities (shape: [n_samples, 2]).
        label_encoder: Optional LabelEncoder.
        save: If True, saves the plot to screenshots/.

    Returns:
        matplotlib Figure object.
    """
    # Use probability of the positive class (Suspicious)
    if y_proba.ndim == 2:
        y_score = y_proba[:, 1]
    else:
        y_score = y_proba

    fpr, tpr, _ = roc_curve(y_true, y_score)
    roc_auc = auc(fpr, tpr)

    fig, ax = plt.subplots(figsize=(8, 6))
    ax.plot(
        fpr, tpr,
        color=COLORS["primary"], linewidth=2.5,
        label=f"ROC Curve (AUC = {roc_auc:.4f})",
    )
    ax.plot(
        [0, 1], [0, 1],
        color="gray", linewidth=1, linestyle="--",
        label="Random Classifier",
    )
    ax.fill_between(fpr, tpr, alpha=0.1, color=COLORS["primary"])

    ax.set_xlim([0.0, 1.0])
    ax.set_ylim([0.0, 1.05])
    ax.set_xlabel("False Positive Rate", fontsize=13)
    ax.set_ylabel("True Positive Rate", fontsize=13)
    ax.set_title("ROC Curve", fontsize=16, fontweight="bold", pad=15)
    ax.legend(loc="lower right", fontsize=11)
    ax.grid(True, alpha=0.3)

    plt.tight_layout()

    if save:
        path = str(SCREENSHOTS_DIR / "roc_curve.png")
        fig.savefig(path)
        logger.info(f"ROC curve saved: {path}")

    return fig


def plot_model_comparison(
    results: Dict[str, Dict[str, float]],
    save: bool = True,
) -> plt.Figure:
    """
    Plot a grouped bar chart comparing all models across metrics.

    Args:
        results: Dict of model name → metrics dict.
        save: If True, saves the plot to screenshots/.

    Returns:
        matplotlib Figure object.
    """
    df = pd.DataFrame(results).T
    metrics_to_plot = ["accuracy", "precision", "recall", "f1_score"]
    df_plot = df[metrics_to_plot]

    fig, ax = plt.subplots(figsize=(12, 6))
    x = np.arange(len(df_plot))
    width = 0.18
    colors = ["#3498db", "#2ecc71", "#e67e22", "#9b59b6"]

    for i, (metric, color) in enumerate(zip(metrics_to_plot, colors)):
        bars = ax.bar(x + i * width, df_plot[metric], width, label=metric.replace("_", " ").title(), color=color)
        # Add value labels on bars
        for bar in bars:
            height = bar.get_height()
            ax.text(
                bar.get_x() + bar.get_width() / 2., height + 0.005,
                f'{height:.3f}', ha='center', va='bottom', fontsize=8,
            )

    ax.set_xlabel("Model", fontsize=13)
    ax.set_ylabel("Score", fontsize=13)
    ax.set_title("Model Comparison", fontsize=16, fontweight="bold", pad=15)
    ax.set_xticks(x + width * 1.5)
    ax.set_xticklabels(df_plot.index, rotation=15, ha="right")
    ax.legend(loc="lower right")
    ax.set_ylim(0, 1.12)
    ax.grid(axis="y", alpha=0.3)

    plt.tight_layout()

    if save:
        path = str(SCREENSHOTS_DIR / "model_comparison.png")
        fig.savefig(path)
        logger.info(f"Model comparison saved: {path}")

    return fig


def plot_feature_importance(
    model: Any,
    vectorizer: Any,
    top_n: int = 20,
    save: bool = True,
) -> Optional[plt.Figure]:
    """
    Plot feature importance for models that support it.

    Works with: Logistic Regression (coefficients), Random Forest (feature_importances_).

    Args:
        model: Trained model.
        vectorizer: Fitted vectorizer with feature names.
        top_n: Number of top features to display.
        save: If True, saves the plot to screenshots/.

    Returns:
        matplotlib Figure or None if model doesn't support feature importance.
    """
    feature_names = vectorizer.get_feature_names_out()

    # Extract importance scores
    if hasattr(model, "feature_importances_"):
        importances = model.feature_importances_
    elif hasattr(model, "coef_"):
        importances = np.abs(model.coef_[0]) if model.coef_.ndim > 1 else np.abs(model.coef_)
    elif hasattr(model, "estimator") and hasattr(model.estimator, "coef_"):
        importances = np.abs(model.estimator.coef_[0])
    else:
        # For CalibratedClassifierCV, try to access base estimator
        if hasattr(model, "calibrated_classifiers_"):
            base = model.calibrated_classifiers_[0].estimator
            if hasattr(base, "coef_"):
                importances = np.abs(base.coef_[0])
            else:
                logger.warning("Model does not support feature importance extraction")
                return None
        else:
            logger.warning("Model does not support feature importance extraction")
            return None

    # Get top features
    indices = np.argsort(importances)[-top_n:]
    top_features = feature_names[indices]
    top_importances = importances[indices]

    fig, ax = plt.subplots(figsize=(10, 8))
    colors = plt.cm.viridis(np.linspace(0.3, 0.9, len(top_features)))

    ax.barh(range(len(top_features)), top_importances, color=colors)
    ax.set_yticks(range(len(top_features)))
    ax.set_yticklabels(top_features, fontsize=10)
    ax.set_xlabel("Importance Score", fontsize=13)
    ax.set_title(f"Top {top_n} Feature Importances", fontsize=16, fontweight="bold", pad=15)
    ax.grid(axis="x", alpha=0.3)

    plt.tight_layout()

    if save:
        path = str(SCREENSHOTS_DIR / "feature_importance.png")
        fig.savefig(path)
        logger.info(f"Feature importance saved: {path}")

    return fig


def plot_dataset_distribution(
    df: pd.DataFrame,
    save: bool = True,
) -> plt.Figure:
    """
    Plot the distribution of Genuine vs Suspicious labels.

    Args:
        df: DataFrame with 'Label' column.
        save: If True, saves the plot to screenshots/.

    Returns:
        matplotlib Figure object.
    """
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    # Bar chart
    label_counts = df["Label"].value_counts()
    colors = [COLORS["genuine"], COLORS["suspicious"]]
    label_counts.plot(kind="bar", ax=axes[0], color=colors, edgecolor="white", linewidth=1.5)
    axes[0].set_title("Label Distribution", fontsize=14, fontweight="bold")
    axes[0].set_xlabel("Label")
    axes[0].set_ylabel("Count")
    axes[0].tick_params(axis="x", rotation=0)

    # Add count labels
    for i, (label, count) in enumerate(label_counts.items()):
        axes[0].text(i, count + 10, str(count), ha="center", fontweight="bold", fontsize=12)

    # Pie chart
    axes[1].pie(
        label_counts, labels=label_counts.index, autopct="%1.1f%%",
        colors=colors, startangle=90,
        textprops={"fontsize": 12}, pctdistance=0.85,
        wedgeprops={"edgecolor": "white", "linewidth": 2},
    )
    centre_circle = plt.Circle((0, 0), 0.60, fc="white")
    axes[1].add_artist(centre_circle)
    axes[1].set_title("Label Proportions", fontsize=14, fontweight="bold")

    plt.suptitle("Dataset Distribution", fontsize=16, fontweight="bold", y=1.02)
    plt.tight_layout()

    if save:
        path = str(SCREENSHOTS_DIR / "dataset_distribution.png")
        fig.savefig(path)
        logger.info(f"Dataset distribution saved: {path}")

    return fig


def plot_top_manufacturers(
    df: pd.DataFrame,
    top_n: int = 15,
    save: bool = True,
) -> plt.Figure:
    """
    Plot the most frequent manufacturers in the dataset.

    Args:
        df: DataFrame with 'Manufacturer' column.
        top_n: Number of top manufacturers to show.
        save: If True, saves the plot to screenshots/.

    Returns:
        matplotlib Figure object.
    """
    fig, ax = plt.subplots(figsize=(12, 7))

    manufacturer_col = "Manufacturer" if "Manufacturer" in df.columns else "manufacturer"
    top = df[manufacturer_col].value_counts().head(top_n)

    colors = plt.cm.Set2(np.linspace(0, 1, len(top)))
    top.plot(kind="barh", ax=ax, color=colors, edgecolor="white", linewidth=0.8)

    ax.set_xlabel("Count", fontsize=13)
    ax.set_ylabel("")
    ax.set_title(f"Top {top_n} Manufacturers", fontsize=16, fontweight="bold", pad=15)
    ax.grid(axis="x", alpha=0.3)
    ax.invert_yaxis()

    plt.tight_layout()

    if save:
        path = str(SCREENSHOTS_DIR / "top_manufacturers.png")
        fig.savefig(path)
        logger.info(f"Top manufacturers saved: {path}")

    return fig


def plot_drug_frequency(
    df: pd.DataFrame,
    top_n: int = 15,
    save: bool = True,
) -> plt.Figure:
    """
    Plot the most frequent drug names in the dataset.

    Args:
        df: DataFrame with 'DrugName' column.
        top_n: Number of top drugs to show.
        save: If True, saves the plot to screenshots/.

    Returns:
        matplotlib Figure object.
    """
    fig, ax = plt.subplots(figsize=(12, 7))

    drug_col = "DrugName" if "DrugName" in df.columns else "drugname"
    top = df[drug_col].value_counts().head(top_n)

    colors = plt.cm.Paired(np.linspace(0, 1, len(top)))
    top.plot(kind="barh", ax=ax, color=colors, edgecolor="white", linewidth=0.8)

    ax.set_xlabel("Count", fontsize=13)
    ax.set_ylabel("")
    ax.set_title(f"Top {top_n} Drug Names", fontsize=16, fontweight="bold", pad=15)
    ax.grid(axis="x", alpha=0.3)
    ax.invert_yaxis()

    plt.tight_layout()

    if save:
        path = str(SCREENSHOTS_DIR / "drug_frequency.png")
        fig.savefig(path)
        logger.info(f"Drug frequency saved: {path}")

    return fig


# ==============================================================================
# Full Evaluation Pipeline
# ==============================================================================

def run_evaluation(pipeline_output: Dict[str, Any]) -> Dict[str, Any]:
    """
    Run the complete evaluation pipeline with all plots.

    Args:
        pipeline_output: Output dictionary from train_model.run_training_pipeline().

    Returns:
        Dict with metrics, classification report, and figure objects.
    """
    logger.info("=" * 60)
    logger.info("  FakeDrugChecker — Model Evaluation")
    logger.info("=" * 60)

    y_test = pipeline_output["y_test"]
    y_pred = pipeline_output["y_pred"]
    y_proba = pipeline_output.get("y_proba")
    label_encoder = pipeline_output["label_encoder"]
    results = pipeline_output["results"]
    best_model = pipeline_output["best_model"]
    vectorizer = pipeline_output["vectorizer"]
    df_clean = pipeline_output["df_clean"]

    # Compute metrics
    metrics = compute_metrics(y_test, y_pred, label_encoder)

    # Classification report
    report = generate_classification_report(y_test, y_pred, label_encoder)

    # Generate all plots
    fig_cm = plot_confusion_matrix(y_test, y_pred, label_encoder)

    fig_roc = None
    if y_proba is not None:
        fig_roc = plot_roc_curve(y_test, y_proba, label_encoder)

    fig_comparison = plot_model_comparison(results)
    fig_importance = plot_feature_importance(best_model, vectorizer)
    fig_distribution = plot_dataset_distribution(df_clean)
    fig_manufacturers = plot_top_manufacturers(df_clean)
    fig_drugs = plot_drug_frequency(df_clean)

    # Close all figures to free memory
    plt.close("all")

    return {
        "metrics": metrics,
        "classification_report": report,
        "figures": {
            "confusion_matrix": fig_cm,
            "roc_curve": fig_roc,
            "model_comparison": fig_comparison,
            "feature_importance": fig_importance,
            "dataset_distribution": fig_distribution,
            "top_manufacturers": fig_manufacturers,
            "drug_frequency": fig_drugs,
        },
    }


# ==============================================================================
# Main — Run evaluation standalone
# ==============================================================================

if __name__ == "__main__":
    from src.train_model import run_training_pipeline

    print("=" * 60)
    print("  FakeDrugChecker — Evaluation")
    print("=" * 60)

    pipeline_output = run_training_pipeline()
    eval_results = run_evaluation(pipeline_output)

    print("\n" + "=" * 60)
    print("  Evaluation Complete")
    print("=" * 60)
    print(f"\nMetrics: {eval_results['metrics']}")
    print(f"\n{eval_results['classification_report']}")
    print(f"\nAll plots saved to: {SCREENSHOTS_DIR}")
