import os
from datetime import datetime

import django
from django.db import connection
from tabulate import tabulate  # 일단은 콘솔 형태로 출력되게 하기 위해서


# Django 설정 불러오기
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "BirderServer.settings")
django.setup()


def format_coord(lat, lon):
    lat_dir = "N" if lat >= 0 else "S"
    lon_dir = "E" if lon >= 0 else "W"
    return f"{abs(lat):.0f}°{lat_dir} {abs(lon):.0f}°{lon_dir}"


def ensure_datetime(value):
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(str(value))


def format_datetime(dt_value):
    dt = ensure_datetime(dt_value)
    return dt.strftime("%Y.%m.%d"), dt.strftime("%H:%M:%S")

# DB 구조에 따라서 내용 달라질 예정
def print_city_logs(city_name):
    with connection.cursor() as cur:
        cur.execute(
            """
            SELECT lat, lon, location_desc, observed_at
            FROM bird_logs
            WHERE city = %s
            ORDER BY observed_at DESC
            """,
            [city_name],
        )
        rows = cur.fetchall()

    print(f"\n{city_name} 도요새 상세 관측 기록")
    print("-" * 40)

    table = []
    for lat, lon, desc, observed_at in rows:
        coord = format_coord(lat, lon)
        date_str, time_str = format_datetime(observed_at)

        loc_cell = f"{coord}\n{desc}"
        date_cell = f"{date_str}\n{time_str}"

        table.append([loc_cell, date_cell])

    headers = ["관측 위치", "관측 일자"]
    print(tabulate(table, headers=headers, tablefmt="github"))


if __name__ == "__main__":
    print_city_logs("대구광역시")
    print_city_logs("서울특별시")
