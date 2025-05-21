# my_analysis_project/auth_app/admin.py
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.hashers import make_password
from analysis.models import OrganismAccess, MotifAccess, AnalysisHistory
from auth_app.models import UserColorPreference, OrganismGroup


class CustomUserAdmin(UserAdmin):
    """Customize the Django Admin User Interface"""
    fieldsets = (
        (None, {"fields": ("username", "password")}),
        ("Personal Info", {"fields": ("first_name", "last_name", "email")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important Dates", {"fields": ("last_login", "date_joined")}),
    )

    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("username", "password1", "password2"),
        }),
    )

    list_display = ("username", "email", "is_staff", "is_superuser")
    search_fields = ("username", "email")
    ordering = ("username",)

    def save_model(self, request, obj, form, change):
        """Ensure password is always hashed before saving."""
        if form.cleaned_data.get("password") and not obj.password.startswith("pbkdf2_sha256$"):
            obj.password = make_password(form.cleaned_data["password"])
        super().save_model(request, obj, form, change)


class UserColorPreferenceAdmin(admin.ModelAdmin):
    list_display = ('user', 'preference_type', 'name', 'color', 'stroke_width')
    list_filter = ('preference_type', 'user')
    search_fields = ('name', 'user__username')


class OrganismGroupAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    search_fields = ('name',)
    filter_horizontal = ('members',)


class OrganismAccessAdmin(admin.ModelAdmin):
    list_display = ('organism_name', 'access_type', 'group', 'user')
    list_filter = ('access_type',)
    search_fields = ('organism_name', 'group__name', 'user__username')


class MotifAccessAdmin(admin.ModelAdmin):
    list_display = ('motif_name', 'access_type', 'group', 'user')
    list_filter = ('access_type',)
    search_fields = ('motif_name', 'group__name', 'user__username')


class AnalysisHistoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'name', 'created_at')
    list_filter = ('user', 'created_at')
    search_fields = ('name', 'user__username')
    readonly_fields = ('created_at',)

admin.site.register(UserColorPreference, UserColorPreferenceAdmin)
admin.site.register(OrganismGroup, OrganismGroupAdmin)
admin.site.register(OrganismAccess, OrganismAccessAdmin)
admin.site.register(MotifAccess, MotifAccessAdmin)
admin.site.register(AnalysisHistory, AnalysisHistoryAdmin)

