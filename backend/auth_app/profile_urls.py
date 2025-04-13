from django.urls import path
from auth_app.views.user_profile_views import (
    get_user_profile,
    get_analysis_settings
)

urlpatterns = [
    path('', get_user_profile, name='user_profile'),
    path('analysis-settings/<int:analysis_id>/', get_analysis_settings, name='analysis_settings'),
]