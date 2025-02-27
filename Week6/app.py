import streamlit as st
import torch
import cv2
import numpy as np
import librosa
import os
from transformers import pipeline
from diffusers import StableDiffusionPipeline
import matplotlib.pyplot as plt
import subprocess

# Load YOLOv5 model
def load_yolo_model(model_path):
    model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path, force_reload=True)
    return model

# Load a speech emotion analysis model
def load_speech_emotion_model():
    emotion_model = pipeline("audio-classification", model="ehcalabres/wav2vec2-lg-xlsr-en-speech-emotion-recognition")
    return emotion_model

# Perform fall detection using YOLOv5
def detect_fall(image_path, model_path):
    subprocess.run(["python", "yolov5/detect.py", "--weights", model_path, "--source", image_path, "--save-txt", "--save-crop"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    detect_dir = "yolov5/runs/detect/"
    exp_dirs = sorted([d for d in os.listdir(detect_dir) if d.startswith("exp")], key=lambda x: int(x[3:]) if x[3:].isdigit() else 0)
    
    if not exp_dirs:
        return None
    
    latest_exp_dir = os.path.join(detect_dir, exp_dirs[-1])
    detected_image_path = os.path.join(latest_exp_dir, os.path.basename(image_path))
    
    return detected_image_path if os.path.exists(detected_image_path) else None

# Perform speech emotion analysis
def analyze_speech_emotion(audio_path, emotion_model):
    audio, sr = librosa.load(audio_path, sr=16000, mono=True, res_type="kaiser_fast")
    results = emotion_model(audio[:sr*3])
    return max(results, key=lambda x: x['score'])['label'] if results else "No emotion detected."

# Generate description of detected image
def describe_detected_image(image_path):
    if image_path is None:
        return "No image detected to describe."
    
    description = f"The detected image at {image_path} likely contains a scene related to fall detection, highlighting an individual in distress or an annotated detection box."
    return description

# Streamlit UI
st.title("Fall Detection and Emotion Analysis")

uploaded_image = st.file_uploader("Upload an image for fall detection", type=["jpg", "png", "jpeg"])
uploaded_audio = st.file_uploader("Upload an audio file for emotion analysis", type=["wav", "mp3"])
model_path = st.text_input("Enter YOLOv5 model path", "best.pt")

yolo_model = load_yolo_model(model_path)
emotion_model = load_speech_emotion_model()

if st.button("Run Analysis"):
    if uploaded_image:
        image_path = f"temp_{uploaded_image.name}"
        with open(image_path, "wb") as f:
            f.write(uploaded_image.getbuffer())
        
        detected_image_path = detect_fall(image_path, model_path)
        if detected_image_path:
            st.image(detected_image_path, caption="Detected Fall", use_container_width=True)
            image_description = describe_detected_image(detected_image_path)
            st.write("Image Description:", image_description)
        else:
            st.error("No fall detected or detection failed.")
    
    if uploaded_audio:
        audio_path = f"temp_{uploaded_audio.name}"
        with open(audio_path, "wb") as f:
            f.write(uploaded_audio.getbuffer())
        
        emotion_result = analyze_speech_emotion(audio_path, emotion_model)
        st.write("Speech Emotion Analysis:", emotion_result)
