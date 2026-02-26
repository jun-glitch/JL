# Birder 🦜 
### OpenAI Vision API 기반 새 종 판별 및 탐조 기록 서비스

![Python](https://img.shields.io/badge/Python-3.10-blue?logo=python&logoColor=white)
![Django](https://img.shields.io/badge/Django-5.x-092E20?logo=django&logoColor=white)
![DRF](https://img.shields.io/badge/DRF-REST_Framework-red?logo=django&logoColor=white)
![GeoDjango](https://img.shields.io/badge/GeoDjango-GIS-green)
![GitHub](https://img.shields.io/badge/GitHub-Repo-181717?logo=github)
![Supabase](https://img.shields.io/badge/Supabase-Storage%20%2B%20Postgres-3ECF8E?logo=supabase&logoColor=white) 
---

Birder는 **OpenAI Vision API를 활용한 조류 종 분류**, **개인 도감**, **위치 기반 관측 기록 조회 기능**을 제공하는 탐조(Bird Watching) 어플입니다.

사용자가 사진을 업로드하면 AI가 새의 종을 자동으로 판별하고,  
관찰 위치와 시간을 함께 저장하여 정보 검색이 가능하며,  
나만의 도감을 채워 나가는 형태의 새로운 탐조 경험을 제공합니다.

---

## 📌 주요 기능 (Features)

### 1. **OpenAI Vision API 기반 조류 종 판별**
- 이미지를 촬영 혹은 업로드 하여 종 검색 가능
- 사용자가 업로드한 새 이미지 EXIF에서 위치(GPS) 및 촬영 시간 추출  
- OpenAI Vision API 호출  
- DB에 등록된 525종 중에서만 Top-5 후보 반환
- Wikimedia API를 통한 종 대표 이미지 자동 조회

### 2. **개인 도감(My Species Book)**
- 발견한 종 이미지 및 위치, 시간, 종 정보 저장
- 동일 종 반복 관찰 시 기록(사진/위치/날짜) 누적 저장

### 3. **지역/종별 탐조 정보 제공**
- 사진 EXIF 또는 사용자 입력 기반 위도/경도 저장
- 기간별 관측 데이터 필터링
- 종별 관측 횟수 집계 (개인 도감/기록 통계)  
- 예:  
  - “까치 관측 기록 조회”  
  - “대구 지역에서 최근 관찰된 새 보기”  

---

## 🏗️ 기술 스택 (Tech Stack)

### **Backend**
- Python 3.10  
- Django 5.x  
- Django REST Framework  

### **Frontend**
- Flutter

### **AI**
- OpenAI Vision API

### **Database / Storage**
- Supabase

### **Open APIs**
- Wikimedia API

---

## 🗂️ 프로젝트 구조 (Project Structure)

```bash
├── birder_backend/
│   ├── config/                # Django settings, ASGI/WSGI, project urls
│   ├── integrations/          # Supabase client, authentication
│   ├── accounts/              # 사용자 관리 (회원가입, 로그인 등)
│   ├── birds/
│   │   ├── services/          # OpenAI 호출 로직 (identify.py, openai_identify.py)
│   │   ├── serializers_*.py   # API 응답/요청 serializer
│   │   ├── views*.py          # 업로드, 종 선택, 로그 조회 API
│   │   └── models.py          # photo, species, log 모델 정의
│   ├── manage.py
│   └── requirements.txt
│
├── birder_frontend/
│   ├── lib/
│   │   ├── screens/           # 주요 화면 (로그, 종 검색, 지도 등)
│   │   ├── services/          # Backend API 호출 로직
│   │   └── models/            # 데이터 모델
│   ├── pubspec.yaml
│   └── main.dart
│
└── README.md
---

## 📈 Project Roadmap

- [x] 요구사항 정의  
- [x] Figma 프로토타입  
- [x] Backend 개발  
- [x] Frontend 개발    
- [ ] 통합 테스트  
