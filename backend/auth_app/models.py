#my_analysis_project/auth_app/models.py
from django.conf import settings
from django.contrib import admin
from django.contrib.auth.admin import GroupAdmin
from django.contrib.auth.models import Group
from django.contrib.auth.models import User
from django.core.validators import RegexValidator
from django.db import models
from django.utils.translation import gettext_lazy as _

admin.site.unregister(Group)


@admin.register(Group)
class CustomGroupAdmin(GroupAdmin):
    def save_model(self, request, obj, form, change):
        if not change:
            permissions = form.cleaned_data.get('permissions')
            form.cleaned_data['permissions'] = []
            super().save_model(request, obj, form, change)

            if permissions:
                obj.permissions.set(permissions)
        else:
            super().save_model(request, obj, form, change)

class OrganismGroup(models.Model):
    """
    Groups for organizing organism access permissions.
    Users can be assigned to groups to get access to specific organisms.
    """
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    members = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name='organism_groups',
        blank=True
    )

    class Meta:
        verbose_name = _('Organism Group')
        verbose_name_plural = _('Organism Groups')

    def __str__(self):
        return self.name



class UserColorPreference(models.Model):
    MOTIF = 'motif'
    STAGE = 'stage'

    TYPE_CHOICES = (
        (MOTIF, 'Motif'),
        (STAGE, 'Stage'),
    )

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='color_preferences'
    )
    preference_type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    name = models.CharField(max_length=255)
    color = models.CharField(
        max_length=9,
        validators=[
            RegexValidator(
                r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$',
                'Enter a valid hex color code'
            )
        ],
    )
    stroke_width = models.PositiveSmallIntegerField(default=4)

    class Meta:
        unique_together = ('user', 'preference_type', 'name')