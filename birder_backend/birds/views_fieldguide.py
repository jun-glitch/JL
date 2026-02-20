from collections import defaultdict

from django.db.models import Count, Max, Q
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from config import settings

from integrations.supabase_client import supabase

class FieldGuideView(APIView):
    """
    도감 메인:
    - Species(마스터)를 order(목) 기준으로 그룹핑
    - 로그인 유저의 Log를 집계해서:
      observed 여부, observation_count, last_observed_at, cover_image_url(최근 1장) 제공
    검색/필터:
    - ?order=기러기목 (목별 필터)
    - ?q=청둥 (학명 부분검색)
    - ?observed=true|false (관측한 종만/관측 안한 종만)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # 프론트에서 보내는 검색 파라미터 읽기
        kwd = request.query_params.get("kwd")

        try:
            # Species 먼저 필터링
            query = supabase.table('species').select('species_code', 'common_name', 'scientific_name', 'order_name', 'family_name')
            if kwd:
                query = query.or_(f'common_name.ilike.%{kwd}%,scientific_name.ilike.%{kwd}%')
            
            response = query.order('order_name', desc=False).execute()
            all_data = response.data

            user_logs_res = supabase.table('log').select(
                    'species_code', 'reg_date',
                    'photo_num(obs_date, s_filenum)'
                ).eq('id', request.user.id).execute()
            
            user_logs = user_logs_res.data

            user_stats = {}
            for log in user_logs:
                code = log['species_code']
                photo = log.get('photo_num') # 조인된 포토 데이터
                date = photo['obs_date'] if photo['obs_date'] else log['reg_date']

                if code not in user_stats:
                    user_stats[code] = {
                        "observation_count": 0,
                        "last_observed_at": date,
                        "cover_image_url": f"{photo['s_filenum']}"
                    }
                
                user_stats[code]["observation_count"] += 1
                # 더 최신 날짜라면 이미지와 날짜 갱신
                if date > user_stats[code]["last_observed_at"]:
                    user_stats[code]["last_observed_at"] = date
                    user_stats[code]["cover_image_url"] = f"{photo['s_filenum']}"

            grouped_res = {}
            order_names = []

            for entry in all_data:
                order = entry['order_name']
                code = entry['species_code']

                if order not in grouped_res:
                    grouped_res[order] = []
                    order_names.append(order)

                if code in user_stats:
                    entry['observed'] = True
                    entry['observation_count'] = user_stats[code]['observation_count']
                    entry['last_observed_at'] = user_stats[code]['last_observed_at']
                    entry['cover_image_url'] = user_stats[code]['cover_image_url']
                else:
                    entry['observed'] = False
                    entry['observation_count'] = 0
                    entry['last_observed_at'] = None
                    entry['cover_image_url'] = None
                
                # entry['observed'] = False
                grouped_res[order].append(entry)

            return Response({
                "order_list" : order_names,
                "species_data" : grouped_res
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"message" : f"도감 불러오기 중 에러 발생: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
