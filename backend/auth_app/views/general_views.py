from django.contrib.auth import authenticate, logout
from django.http import JsonResponse
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken


# AUTHENTICATION
@swagger_auto_schema(
    method='post',
    operation_description="Authenticate a user and return access tokens.",
    request_body=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        properties={
            'username': openapi.Schema(type=openapi.TYPE_STRING),
            'password': openapi.Schema(type=openapi.TYPE_STRING)
        },
        required=['username', 'password']
    ),
    responses={
        200: openapi.Response("Tokens", openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                "refresh": openapi.Schema(type=openapi.TYPE_STRING),
                "access": openapi.Schema(type=openapi.TYPE_STRING)
            }
        )),
        401: "Invalid credentials"
    }
)
@api_view(["POST"])
@permission_classes([AllowAny])
def login_view(request):
    username = request.data.get("username")
    password = request.data.get("password")

    user = authenticate(username=username, password=password)
    if user:
        refresh = RefreshToken.for_user(user)
        return Response({"refresh": str(refresh), "access": str(refresh.access_token)})
    return Response({"error": "Invalid credentials"}, status=401)


@swagger_auto_schema(
    method='post',
    operation_description="Logout user by blacklisting refresh token.",
    request_body=openapi.Schema(
        type=openapi.TYPE_OBJECT,
        properties={
            'refresh': openapi.Schema(type=openapi.TYPE_STRING)
        },
        required=['refresh']
    ),
    responses={
        200: "Logout successful",
        400: "Invalid token"
    }
)
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def logout_view(request):
    if request.user.is_authenticated:
        if hasattr(request.user, 'auth_token'):
            request.user.auth_token.delete()
        logout(request)
        request.session.flush()
        return JsonResponse({"success": True})
    return JsonResponse({"success": False}, status=401)
