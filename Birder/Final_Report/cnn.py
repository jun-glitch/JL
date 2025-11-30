import os
from pathlib import Path

import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
from PIL import Image

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

DATA_DIR = "data" # data/train/(새종이름)/(이니셜+숫자).jpg 구조를 가진다
MODEL_PATH = "simple_bird_cnn.pth"
BATCH_SIZE = 8
NUM_EPOCHS = 15
LR = 1e-3


# 데이터셋
def get_dataloader():
    transform = transforms.Compose([
        transforms.Resize((128, 128)),
        transforms.ToTensor(),  
    ])

    train_dataset = datasets.ImageFolder(
        root=os.path.join(DATA_DIR, "train"),
        transform=transform
    )
    train_loader = DataLoader(
        train_dataset, batch_size=BATCH_SIZE, shuffle=True
    )

    class_names = train_dataset.classes 
    return train_loader, class_names


# CNN 모델 
class SimpleCNN(nn.Module):
    def __init__(self, num_classes):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 16, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),      

            nn.Conv2d(16, 32, 3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),    

            nn.Conv2d(32, 64, 3, padding=1),
            nn.ReLU(),
            nn.MaxPool2d(2),      
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Linear(64 * 16 * 16, 128),
            nn.ReLU(),
            nn.Linear(128, num_classes),
        )

    def forward(self, x):
        x = self.features(x)
        x = self.classifier(x)
        return x


# 학습 
def train():
    train_loader, class_names = get_dataloader()
    num_classes = len(class_names)

    model = SimpleCNN(num_classes).to(DEVICE)
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=LR)

    model.train()
    for epoch in range(NUM_EPOCHS):
        running_loss = 0.0
        running_corrects = 0
        total = 0

        for imgs, labels in train_loader:
            imgs = imgs.to(DEVICE)
            labels = labels.to(DEVICE)

            optimizer.zero_grad()

            outputs = model(imgs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item() * imgs.size(0)
            _, preds = torch.max(outputs, 1)
            running_corrects += torch.sum(preds == labels)
            total += labels.size(0)

        epoch_loss = running_loss / total
        epoch_acc = running_corrects.double() / total
        print(f"Epoch {epoch+1}/{NUM_EPOCHS} "
              f"Loss: {epoch_loss:.4f} Acc: {epoch_acc:.4f}")

    torch.save({
        "model_state_dict": model.state_dict(),
        "class_names": class_names
    }, MODEL_PATH)
    print(f"모델 저장 완료: {MODEL_PATH}")


# 예측 
def predict(image_path):
    checkpoint = torch.load(MODEL_PATH, map_location=DEVICE)
    class_names = checkpoint["class_names"]
    num_classes = len(class_names)

    model = SimpleCNN(num_classes).to(DEVICE)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    transform = transforms.Compose([
        transforms.Resize((128, 128)),
        transforms.ToTensor(),
    ])

    img = Image.open(image_path).convert("RGB")
    x = transform(img).unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        outputs = model(x)
        probs = torch.softmax(outputs, dim=1)
        top_prob, top_idx = torch.max(probs, dim=1)

    predicted_class = class_names[top_idx.item()]
    confidence = top_prob.item()
    print(f"이미지: {image_path}")
    print(f"예측 클래스: {predicted_class} (신뢰도: {confidence:.2%})")


# 실행 
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["train", "predict"], default="train")
    parser.add_argument("--image", type=str, help="예측에 사용할 이미지 경로")
    args = parser.parse_args()

    if args.mode == "train":
        train()
    elif args.mode == "predict":
        if not args.image:
            raise ValueError("--image 경로를 지정해 주세요.")
        predict(args.image)