import sqlite3
from tabulate import tabulate
from datetime import datetime

DB_PATH = "/Users/yusun/Desktop/JL/test_bird.db"

def format_coord(lat, lon):
    lat_dir = "N" if lat >= 0 else "S"
    lon_dir = "E" if lon >= 0 else "W"
    return f"{abs(lat):.0f}°{lat_dir} {abs(lon):.0f}°{lon_dir}"

def format_datetime(dt_str):
    dt = datetime.fromisoformat(dt_str)
    return dt.strftime("%Y.%m.%d"), dt.strftime("%H:%M:%S")

def print_city_logs(city_name):
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
        SELECT lat, lon, location_desc, observed_at
        FROM bird_logs
        WHERE city = ?
        ORDER BY observed_at DESC
    """, (city_name,))
    rows = cur.fetchall()
    conn.close()

    print(f"\n{city_name} 도요새 상세 관측 기록")
    print("-" * 60)

    if not rows:
        print("(해당 도시 데이터 없음)")
        return

    table = []
    for lat, lon, desc, observed_at in rows:
        coord = format_coord(lat, lon)
        date_str, time_str = format_datetime(observed_at)

        # 각 값을 별도 컬럼에 넣기
        table.append([coord, desc, date_str, time_str])

    headers = ["관측 위치", "세부 위치", "관측 일자", "관측 시각"]

    print(
        tabulate(
            table,
            headers=headers,
            tablefmt="github",
            colalign=("center", "left", "center", "center"),
        )
    )

if __name__ == "__main__":
    print_city_logs("대구광역시")
    print_city_logs("서울특별시")
