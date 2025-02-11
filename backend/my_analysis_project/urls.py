from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/analysis/', include('analysis_app.urls')),
    path('api/auth/', include('auth_app.urls')),
]
