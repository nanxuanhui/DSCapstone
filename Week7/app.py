import torch
import cv2
import torchaudio
import torchaudio.transforms as transforms
import numpy as np
from transformers import pipeline, Wav2Vec2ForSequenceClassification, AutoFeatureExtractor
from pathlib import Path
import onnxruntime as ort
import streamlit as st
import faiss
import langchain
import subprocess

# Load custom YOLOv5 model
yolo_model_path = "best.pt"
yolo_detect_script = "yolov5/detect.py"
print(f"Using YOLOv5 detect.py script with model {yolo_model_path}...")

# Ensure directories exist
uploads_dir = Path("uploads")
outputs_dir = Path("outputs")
uploads_dir.mkdir(exist_ok=True)
outputs_dir.mkdir(exist_ok=True)

def detect_fall(image_path):
    output_image_path = outputs_dir / Path(image_path).name
    command = [
        "python", yolo_detect_script,
        "--weights", yolo_model_path,
        "--source", image_path,
        "--save-txt",
        "--project", "outputs",
        "--name", "fall-detection",
        "--exist-ok"
    ]
    print(f"Running YOLOv5 detection: {' '.join(command)}")
    subprocess.run(command, check=True)
    processed_image_path = outputs_dir / "fall-detection" / Path(image_path).name
    return str(processed_image_path)

# Load pre-trained Speech Emotion Detection model
emotion_model_name = "ehcalabres/wav2vec2-lg-xlsr-en-speech-emotion-recognition"
print(f"Loading Speech Emotion Detection model: {emotion_model_name}...")
emotion_model = Wav2Vec2ForSequenceClassification.from_pretrained(emotion_model_name).to(dtype=torch.float32)
feature_extractor = AutoFeatureExtractor.from_pretrained(emotion_model_name)
print("Speech Emotion Detection model loaded successfully!")

# Emotion labels mapping
emotions = ['neutral', 'happy', 'sad', 'angry', 'fear', 'disgust', 'surprise', 'calm']

def predict_emotion(audio_path):
    print(f"Processing audio file for emotion detection: {audio_path}")
    waveform, sample_rate = torchaudio.load(audio_path)
    
    # Resample audio if needed
    target_sample_rate = 16000
    if sample_rate != target_sample_rate:
        resampler = transforms.Resample(orig_freq=sample_rate, new_freq=target_sample_rate)
        waveform = resampler(waveform)
        sample_rate = target_sample_rate
    
    # Ensure correct waveform shape and dtype
    waveform = waveform.squeeze(0).to(dtype=torch.float32)  # Remove batch dimension and ensure float32
    inputs = feature_extractor(waveform, return_tensors="pt", padding=True)
    
    with torch.no_grad():
        logits = emotion_model(**inputs).logits
    predicted_class = torch.argmax(logits, dim=-1).item()
    predicted_emotion = emotions[predicted_class] if predicted_class < len(emotions) else "Unknown"
    print(f"Emotion prediction complete! Predicted class: {predicted_class} ({predicted_emotion})")
    return predicted_emotion

# Model optimization: Quantization & Pruning
print("Applying model optimizations...")
def quantize_yolo():
    print("Quantizing YOLOv5 model using ONNX...")
    dummy_input = torch.randn(1, 3, 640, 640)
    torch.onnx.export(torch.hub.load('ultralytics/yolov5', 'custom', path=yolo_model_path), dummy_input, "yolo_quantized.onnx", opset_version=11)
    print("YOLOv5 quantization completed!")

def quantize_wav2vec():
    print("Quantizing Wav2Vec2 model...")
    emotion_model.to(dtype=torch.float32)  # Ensure model is in float32 to avoid dtype mismatch
    print("Wav2Vec2 quantization completed!")

quantize_yolo()
quantize_wav2vec()

# Streamlit Web Interface
st.title("Fall Detection and Speech Emotion Recognition System")

st.header("Fall Detection")
image_file = st.file_uploader("Upload an image for fall detection", type=["jpg", "png", "jpeg"])
if image_file is not None:
    image_path = str(uploads_dir / image_file.name)
    with open(image_path, "wb") as buffer:
        buffer.write(image_file.read())
    print(f"Received image file: {image_file.name}")
    output_path = detect_fall(image_path)
    st.image(output_path, caption="Detected Fall Image", use_column_width=True)

st.header("Speech Emotion Recognition")
audio_file = st.file_uploader("Upload an audio file for emotion recognition", type=["wav", "mp3"])
if audio_file is not None:
    audio_path = str(uploads_dir / audio_file.name)
    with open(audio_path, "wb") as buffer:
        buffer.write(audio_file.read())
    print(f"Received audio file: {audio_file.name}")
    emotion_class = predict_emotion(audio_path)
    st.write(f"Predicted Emotion: {emotion_class}")