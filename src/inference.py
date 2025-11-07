import json
import os

import joblib
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

# Load pre-trained models (or fall back to training if models don't exist)
MODEL_PATH = os.path.join(os.path.dirname(__file__), "model.pkl")
SCALER_PATH = os.path.join(os.path.dirname(__file__), "scaler.pkl")

if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
    print("Loading pre-trained models...")
    scaler = joblib.load(SCALER_PATH)
    outlier_detector = joblib.load(MODEL_PATH)
    print("Models loaded successfully!")
else:
    print("Warning: Pre-trained models not found. Initializing new models.")
    print("Run 'python train.py' to generate pre-trained models.")
    scaler = StandardScaler()
    outlier_detector = IsolationForest(contamination=0.1, random_state=42)

def handler(event, context):
    try:
        # Parse input data
        body = json.loads(event["body"])
        features = body.get("features", [])
        
        # Data validation
        if not features or not isinstance(features, list):
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "Invalid input: features must be a non-empty array"
                })
            }

        # ML processing
        features_array = np.array(features).reshape(1, -1)
        
        # Use pre-trained scaler (or fit if not pre-trained)
        if hasattr(scaler, 'mean_'):
            # Scaler is already fitted (pre-trained)
            features_scaled = scaler.transform(features_array)
        else:
            # Fall back to fitting (only if models weren't pre-trained)
            features_scaled = scaler.fit_transform(features_array)
        
        # Use pre-trained outlier detector (or fit if not pre-trained)
        if hasattr(outlier_detector, 'estimators_'):
            # Model is already fitted (pre-trained)
            is_outlier = outlier_detector.predict(features_array)[0] == -1
        else:
            # Fall back to fitting (only if models weren't pre-trained)
            is_outlier = outlier_detector.fit_predict(features_array)[0] == -1
        
        # Calculate feature importance
        abs_features = np.abs(features_array[0])
        feature_importance = abs_features / (np.sum(abs_features) + 1e-10)
        
        # Generate prediction response
        prediction = {
            "base_prediction": float(np.mean(features_scaled) * 10),
            "confidence": float(1.0 / (1.0 + np.std(features_scaled))),
            "feature_importance": [float(x) for x in feature_importance],
            "is_anomaly": bool(is_outlier),
            "stats": {
                "mean": float(np.mean(features)),
                "std": float(np.std(features)),
                "min": float(np.min(features)),
                "max": float(np.max(features))
            }
        }

        return {
            "statusCode": 200,
            "body": json.dumps({
                "prediction": prediction,
                "features": features,
                "features_scaled": features_scaled.tolist()[0]
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": f"Internal server error: {str(e)}"
            })
        }        }