from django.db import models

class AppUser(models.Model):
    username = models.CharField(max_length=100, unique=True)
    password_hash = models.CharField(max_length=64)

    def __str__(self):
        return self.username