# Birder 🦜 
### 딥러닝 기반 새 종 판별 및 탐조 기록 서비스

![Python](https://img.shields.io/badge/Python-3.10-blue?logo=python&logoColor=white)
![Django](https://img.shields.io/badge/Django-5.x-092E20?logo=django&logoColor=white)
![DRF](https://img.shields.io/badge/DRF-REST_Framework-red?logo=django&logoColor=white)
![GeoDjango](https://img.shields.io/badge/GeoDjango-GIS-green)
![PyTorch](https://img.shields.io/badge/PyTorch-1.x-EE4C2C?logo=pytorch)
![torchvision](https://img.shields.io/badge/torchvision-latest-orange)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?logo=postgresql)
![PostGIS](https://img.shields.io/badge/PostGIS-3.x-6BA542?logo=postgresql)
![GitHub](https://img.shields.io/badge/GitHub-Repo-181717?logo=github)

---

Birder는 **딥러닝 AI를 활용한 조류 종 분류**, **개인 도감**, **PostGIS 기반 관측 기록 조회 기능**을 제공하는 탐조(Bird Watching) 어플입니다.

사용자가 사진을 업로드하면 AI가 새의 종을 자동으로 판별하고,  
관찰 위치와 시간을 함께 저장하여 정보 검색이 가능하며,  
나만의 도감을 채워 나가는 형태의 새로운 탐조 경험을 제공합니다.

---

## 📌 주요 기능 (Features)

### 1. **딥러닝 기반 조류 종 판별**
- PyTorch + torchvision을 이용한 이미지 분류 모델 학습  
- Wikimedia Commons API 기반 학습 데이터 수집  
- 사용자가 사진 업로드 → AI가 종(species) 자동 판별
- 이미지를 촬영 혹은 업로드 하여 종 검색 가능

### 2. **개인 도감(My Species Book)**
- 발견한 종 이미지 및 위치, 시간, 종 정보 저장
- 동일 종 반복 관찰 시 기록(사진/위치/날짜) 누적 저장

### 3. **지역/종별 탐조 정보 제공**
- PostGIS 공간 질의를 이용한 고성능 지역 검색  
- 예:  
  - “까치 관측 기록 조회”  
  - “대구 지역에서 최근 관찰된 새 보기”  

---

## 🏗️ 기술 스택 (Tech Stack)

### **Backend**
- Python 3.10  
- Django 5.x  
- Django REST Framework  
- PostgreSQL + PostGIS  
- Django Media Storage  

### **AI / ML**
- PyTorch  
- torchvision  

### **Open APIs**
- Wikimedia Commons API
- eBird API

---

## 🗂️ 프로젝트 구조 (Project Structure)

```bash
project/
│
├── backend/
│   ├── manage.py
│   ├── config/
│   ├── api/
│   ├── species/
│   ├── log/
│   ├── birder/
│   └── ml/                # AI 모델 로딩 및 inference
│
├── model/
│   ├── train.ipynb        # 모델 학습 노트북
│   ├── dataset/           # 학습 이미지
│   └── weights/           # 모델 가중치 (.pt)
│
└── frontend/              # (예정)
```
---

## 📈 Project Roadmap

- [x] 요구사항 정의  
- [x] Figma 프로토타입  
- [ ] 딥러닝 모델 학습  
- [ ] Backend API 개발  
- [ ] Frontend 개발    
- [ ] 통합 테스트  
- [ ] 배포  


# flutterpracticeblog

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

