from django.contrib.auth import get_user_model
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin, AbstractUser
from django.db import models

class CustomUserManager(BaseUserManager):
    def create_user(self, username, password=None, **extra_fields):
        if not username:
            raise ValueError("The Username field must be set")
        user = self.model(username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, username, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(username, password, **extra_fields)

class AppUser(AbstractUser):
    """
    Extends Django's built-in User model.
    """
    pass  # We can extend this later if needed

# class UserSelection(models.Model):
#     """
#     Stores the user’s last selected organism, motifs, and stages.
#     """
#     user = models.ForeignKey(AppUser, on_delete=models.CASCADE)
#     organism = models.CharField(max_length=255)

class AnalysisHistory(models.Model):
    """
    Stores past analysis results for each user.
    """
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE)
    name = models.CharField(max_length=255)
    results = models.JSONField(default=dict)
    filtered_results = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)
