from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from integrations.supabase_client import supabase

class SignupSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=15) # 사용자 ID, 15자 이내로 제한
    email = serializers.EmailField() 
    password = serializers.CharField(write_only=True, min_length=8) # 최소 8자, 응답에 노출되지 않게
    password_confirm = serializers.CharField(write_only=True, min_length=8) # DB에 저장되지 않음

    def validate_username(self, value):
        response = supabase.table('birder').select('user_id').eq('user_id', value).execute()
        if response.data:
            raise serializers.ValidationError("이미 사용 중인 ID입니다.")
        return value

    def validate_email(self, value):
        response = supabase.table('birder').select('user_email').eq('user_email', value).execute()
        if response.data:
            raise serializers.ValidationError("이미 사용 중인 이메일입니다.")
        return value

    def validate(self, attrs):
        pw = attrs.get("password")
        pw2 = attrs.pop("password_confirm")

        # 비밀번호 일치 여부 확인
        if pw != pw2:
            raise serializers.ValidationError({"password_confirm": "비밀번호가 일치하지 않습니다."})

        # Django 기본 비밀번호 정책 검증(너무 쉬운 비밀번호 방지 등)
        validate_password(pw)
        return attrs

class UserSettingsSerializer(serializers.Serializer):
    location_enabled = serializers.IntegerField(min_value=0, max_value=1)
    updated_at = serializers.DateTimeField(read_only=True)

    def validate_location_enabled(self, value):
        if value not in [0, 1]:
            raise serializers.ValidationError("값은 0 또는 1이어야 합니다.")
        return value