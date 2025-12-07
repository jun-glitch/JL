import sqlite3
from datetime import datetime

DB_PATH = "/Users/yusun/Desktop/JL/test_bird.db"   

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# 테이블 생성 (실제 DB 구조에 맞게 수정 가능)
cur.execute("""
CREATE TABLE IF NOT EXISTS bird_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    city TEXT NOT NULL,
    lat REAL NOT NULL,
    lon REAL NOT NULL,
    location_desc TEXT NOT NULL,
    observed_at TEXT NOT NULL   
)
""")

# 샘플 데이터
sample_rows = [
    ("대구광역시", 35.0, 128.0, "중랑천 부근", "2025-10-17T16:34:23"),
    ("대구광역시", 35.0, 128.0, "중랑천 부근", "2025-10-17T11:34:23"),
    ("대구광역시", 35.0, 128.0, "중랑천 부근", "2025-10-16T09:34:23"),
    ("서울특별시", 37.0, 127.0, "한강 공원",   "2025-10-15T10:00:00"),
    ("서울특별시", 37.0, 127.0, "한강 공원",   "2025-10-14T08:30:00"),
]

cur.executemany("""
INSERT INTO bird_logs (city, lat, lon, location_desc, observed_at)
VALUES (?, ?, ?, ?, ?)
""", sample_rows)

conn.commit()
conn.close()

print("test_bird.db 생성 & 샘플 데이터 입력 완료!")
