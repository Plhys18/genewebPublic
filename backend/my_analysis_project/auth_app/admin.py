from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.hashers import make_password

from .models import AppUser

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


admin.site.register(AppUser, CustomUserAdmin)
