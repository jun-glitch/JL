from time import timezone
from unittest import result
from django.shortcuts import render

# Create your views here.
import os
import django
import sys
from django.http import JsonResponse
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import log, species, birder
from django.contrib.auth import get_user_model # User 모델 임포트 (birder 모델로 대체됨)

sys.path.append(os.path.dirname(os.path.abspath(__file__))) 
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BirderServer.settings') 
django.setup()


CURRENT_USER = None
User = get_user_model()

def login(username):
    global CURRENT_USER
    CURRENT_USER = username
    print(f"\n{CURRENT_USER} Login")

def get_login_user():
    global CURRENT_USER
    return CURRENT_USER

# 로그인한 유저의 도감 목록
def load_log(species_name=None):
    username = get_login_user()
    try:
        target_user = User.objects.get(id=username)
    except User.DoesNotExist:
        print(f"Error: Cannot find user '{username}'.")
        return []
    if species_name is None:
        unique_species_data = log.objects.filter(
            birder=target_user
        ).values(
            'species_code__common_name'
        ).distinct().order_by('species_code__common_name')

        common_names = [
            item['species_code__common_name'] 
            for item in unique_species_data
        ]
    
        print(f"--- '{username}'s observation list ---")
        print("--------------------------------------")
        for item in common_names:
            print(f"{item}")
    else:
        logs_data = log.objects.filter(
            birder=target_user
            , species_code__common_name__exact=species_name 
        ).values(
            'location'
            , 'obs_date'
        ).order_by('obs_date')

        print(f"--- '{username}'s logs for {species_name} ---")
        print("-------------------------------------------------")

        for item in logs_data:
            date_str = item['obs_date'].strftime('%Y-%m-%d %H:%M')
            print(f"[{date_str}] Location: {item['location']}")
    return

def get_user_observations():
    username = get_login_user()

    try:
        target_user = User.objects.get(id=username)
    except User.DoesNotExist:
        print(f"Error: Cannot find '{username}'")
        return []

    logs = log.objects.filter(
        birder=target_user
    ).select_related('species_code').order_by('obs_date')
    

    results = []
    print(f"--- '{username}'s observation list ---")
    
    for item in logs:
        species_name = item.species_code.common_name if item.species_code else "Cannot find species"
        
        results.append({
            'species_name': species_name
            , 'species_code': item.species_code.species_code
        })
        
        # print(f"[{item.pk}] {species_name} - {item.location} ({item.obs_date.date()})")
        
    return results

# 새로 관측한 종 명을 받아 없다면 도감 업데이트, 있다면 로그 추가
def search(species_name):
    target_user = User.objects.get(id=get_login_user())
    try:
        species_object = species.objects.get(common_name__exact=species_name)
        new_log = log.objects.create(
            birder=target_user
            , species_code=species_object
            , obs_date=timezone.now()
        )

        if (check_log(get_user_observations(), species_object.species_code)):
            print(f"New sighting: '{species_name}'. Entry to your log...")
        else:
            print("Species already registerd. Updating your log...")
        return
    except Exception as e:
        print(f"Error occured saving to DB: {e}")
        return


# 검색한 종이 도감에 등록되어있는지 아닌지 판별
def check_log(logResult, searchResult):
    for item in logResult:
        if (item['species_code']==searchResult):
            return False
    return True
