from django.contrib import admin
from django.urls import path, include
from my_analysis_project.views import check_session
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('auth_app.urls')),
    path('api/analysis/', include('my_analysis_project.analysis.urls')),
    path('api/check_session/', check_session, name="check_session"),
]
