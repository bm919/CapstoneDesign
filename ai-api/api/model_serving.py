# src/app.py

import os
import io
import json
from dotenv import load_dotenv

import torch
import timm
from PIL import Image
from fastapi import FastAPI, File, UploadFile, HTTPException
import torchvision.transforms as transforms

# --------------------
# Load environment variables
# --------------------
load_dotenv()  # .env 파일에서 변수 읽어오기

MODEL_PATH      = os.getenv('MODEL_PATH')
CLASS_JSON_PATH = os.getenv('CLASS_JSON_PATH')
BACKBONE_NAME   = os.getenv('BACKBONE_NAME', 'efficientnet_b0')

# --------------------
# Device 설정
# --------------------
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# --------------------
# Utilities
# --------------------
def get_inference_transform():
    """Inference 시 이미지 전처리 transform."""
    return transforms.Compose([
        transforms.Resize((320, 320)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406],
                             [0.229, 0.224, 0.225]),
    ])

def load_class_names(json_path: str):
    """class_names.json에서 레이블 리스트 로드."""
    if not os.path.exists(json_path):
        raise FileNotFoundError(f"Class JSON not found at {json_path}")
    with open(json_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def load_model_and_labels(model_path: str, backbone_name: str, class_json_path: str):
    """
    - checkpoint 내부에 'model_state_dict', 'state_dict', 혹은 직접 state_dict만 저장된
      모든 경우를 처리합니다.
    - DataParallel로 저장된 경우 'module.' prefix도 제거합니다.
    """
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found at {model_path}")
    ckpt = torch.load(model_path, map_location=device)
    print(">> checkpoint keys:", list(ckpt.keys()))

    # 1) state_dict 추출
    if 'model_state_dict' in ckpt:
        raw_weights = ckpt['model_state_dict']
    elif 'state_dict' in ckpt:
        raw_weights = ckpt['state_dict']
    else:
        # checkpoint 자체가 state_dict인 경우
        raw_weights = ckpt

    # 2) DataParallel로 저장되며 'module.' prefix가 붙은 경우 제거
    state_dict = {k.replace('module.', ''): v for k, v in raw_weights.items()}

    # 3) 클래스 레이블(External JSON) 로드
    class_names = load_class_names(class_json_path)
    num_classes = len(class_names)

    # 4) 모델 생성 및 state_dict 로드
    model = timm.create_model(backbone_name, pretrained=False, num_classes=num_classes)
    load_result = model.load_state_dict(state_dict, strict=False)
    if load_result.missing_keys or load_result.unexpected_keys:
        print(f"⚠️ Missing keys: {load_result.missing_keys}")
        print(f"⚠️ Unexpected keys: {load_result.unexpected_keys}")

    model.to(device).eval()
    return model, class_names

def predict_image(model, class_names, image_bytes: bytes):
    """단일 이미지 예측."""
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    tensor = get_inference_transform()(img).unsqueeze(0).to(device)
    with torch.no_grad():
        logits = model(tensor)
        pred_idx = logits.argmax(dim=1).item()
        confidence = float(torch.softmax(logits, dim=1)[0, pred_idx])
        label = class_names[pred_idx]
    return {'label': label, 'confidence': confidence}

def extract_embedding(model, image_bytes: bytes):
    """이미지에서 임베딩 벡터 추출 (평균 풀링 포함)."""
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    tensor = get_inference_transform()(img).unsqueeze(0).to(device)
    with torch.no_grad():
        features = model.forward_features(tensor)            # (1, 1280, 10, 10)
        pooled = torch.nn.functional.adaptive_avg_pool2d(features, (1, 1))  # (1, 1280, 1, 1)
        embedding = pooled.view(pooled.size(0), -1)          # (1, 1280)
    return embedding.squeeze(0).cpu().numpy().tolist()


# --------------------
# FastAPI App 초기화
# --------------------
app = FastAPI(title="Waste Classification API")

# 서버 시작 시 모델·레이블 로드
try:
    model, class_names = load_model_and_labels(MODEL_PATH, BACKBONE_NAME, CLASS_JSON_PATH)
    print(f"✅ Loaded model ({BACKBONE_NAME}) with {len(class_names)} classes")
except Exception as e:
    print(f"❌ Failed to load model or labels: {e}")

@app.post('/predict')
async def predict(file: UploadFile = File(...)):
    """
    이미지 파일을 받아 분류 결과(label, confidence) 반환
    """
    try:
        img_bytes = await file.read()
        result = predict_image(model, class_names, img_bytes)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post('/embedding')
async def get_embedding(file: UploadFile = File(...)):
    """
    이미지 파일을 받아 임베딩 벡터 반환
    """
    try:
        img_bytes = await file.read()
        embedding = extract_embedding(model, img_bytes)
        return {"embedding": embedding}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get('/waste')
def waste_check():
    """쓰레기 분 엔드포인트 (/waste)."""
    return {"status": "ok"}

# uvicorn 실행 예시 (스크립트로 돌릴 때 주석 해제)
# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run("src.app:app", host="0.0.0.0", port=8000, reload=True)

