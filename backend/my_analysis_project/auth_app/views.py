import json
from django.http import JsonResponse, HttpResponseNotAllowed
from django.views.decorators.csrf import csrf_exempt
from .models import AppUser

@csrf_exempt
def login_view(request):
    print("DEBUG: Received request in login_view")
    print("DEBUG: Request method:", request.method)

    if request.method != 'POST':
        print("DEBUG: Request method not POST; returning 405")
        return HttpResponseNotAllowed(['POST'], 'Only POST is allowed')

    try:
        data = json.loads(request.body)
        print("DEBUG: Parsed JSON data:", data)
    except json.JSONDecodeError:
        print("DEBUG: JSON decoding error; request body:", request.body)
        return JsonResponse({'error': 'Invalid JSON'}, status=400)

    username = data.get('username')
    password_hash = data.get('password_hash')
    print("DEBUG: Username received:", username)
    print("DEBUG: Password hash received:", password_hash)

    if not username or not password_hash:
        print("DEBUG: Missing username or password_hash")
        return JsonResponse({'error': 'Invalid credentials'}, status=403)

    try:
        user = AppUser.objects.get(username=username)
        print("DEBUG: Found user in database:", user)
    except AppUser.DoesNotExist:
        print("DEBUG: User not found for username:", username)
        return JsonResponse({'error': 'Invalid credentials'}, status=403)

    if user.password_hash == password_hash:
        print("DEBUG: Password hash matches for user:", username)
        return JsonResponse({'authenticated': True, 'username': username}, status=200)
    else:
        print("DEBUG: Password hash does not match for user:", username)
        return JsonResponse({'error': 'Invalid credentials'}, status=403)
