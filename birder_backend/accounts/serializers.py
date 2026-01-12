from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from .models import UserSettings

class SignupSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=15) # 사용자 ID, 15자 이내로 제한
    email = serializers.EmailField() 
    password = serializers.CharField(write_only=True, min_length=8) # 최소 8자, 응답에 노출되지 않게
    password_confirm = serializers.CharField(write_only=True, min_length=8) # DB에 저장되지 않음

    def validate_username(self, value):
        if User.objects.filter(username=value).exists(): # 중복 확인
            raise serializers.ValidationError("이미 사용 중인 ID입니다.")
        return value

    def validate_email(self, value):
        if User.objects.filter(email=value).exists(): # 중복 확인
            raise serializers.ValidationError("이미 사용 중인 이메일입니다.")
        return value

    def validate(self, attrs):
        pw = attrs.get("password")
        pw2 = attrs.get("password_confirm")

        # 비밀번호 일치 여부 확인
        if pw != pw2:
            raise serializers.ValidationError({"password_confirm": "비밀번호가 일치하지 않습니다."})

        # Django 기본 비밀번호 정책 검증(너무 쉬운 비밀번호 방지 등)
        validate_password(pw)
        return attrs

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data["username"],
            email=validated_data["email"],
            password=validated_data["password"],  # 비밀번호는 자동으로 해시 처리됨
        )
        UserSettings.objects.create(user=user)
        return user

class UserSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserSettings
        fields = ["notifications_enabled", "location_enabled", "updated_at"]
        read_only_fields = ["updated_at"]