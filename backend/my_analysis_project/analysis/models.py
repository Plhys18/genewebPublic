#my_analysis_project/analysis/models.py
from django.contrib.auth.models import User, Group
from django.core.exceptions import ValidationError
from django.db import models


class AnalysisHistory(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='analysis_history'
    )
    name = models.CharField(max_length=255, db_index=True)
    organism = models.CharField(max_length=255, db_index=True)
    motifs = models.JSONField(default=list)
    stages = models.JSONField(default=list)
    settings = models.JSONField(default=dict)
    filtered_results = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)


class OrganismAccess(models.Model):
    PUBLIC = 'public'
    GROUP = 'group'
    USER = 'user'

    ACCESS_TYPE_CHOICES = (
        (PUBLIC, 'Public'),
        (GROUP, 'Group'),
        (USER, 'User'),
    )

    organism_name = models.CharField(max_length=255, db_index=True)
    access_type = models.CharField(
        max_length=10,
        choices=ACCESS_TYPE_CHOICES,
        default=PUBLIC
    )
    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='organism_access'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='organism_access'
    )

    class Meta:
        unique_together = ('organism_name', 'access_type', 'group', 'user')

    def clean(self):
        if self.access_type == self.GROUP and not self.group:
            raise ValidationError('Group must be specified for group access type')
        if self.access_type == self.USER and not self.user:
            raise ValidationError('User must be specified for user access type')
        if self.access_type == self.PUBLIC and (self.group or self.user):
            raise ValidationError('Public access type should not have group or user specified')

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)