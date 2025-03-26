from django.urls import path
from my_analysis_project.auth_app.views.user_preferences import (
    get_user_preferences,
    set_color_preference,
    delete_color_preference,
    reset_color_preferences
)

urlpatterns = [
    path('', get_user_preferences, name='get_preferences'),
    path('set/', set_color_preference, name='set_preference'),
    path('delete/<int:preference_id>/', delete_color_preference, name='delete_preference'),
    path('reset/', reset_color_preferences, name='reset_preferences'),
]