import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "settings")  # Or "my_analysis_project.settings" if settings.py is in a subfolder

application = get_wsgi_application()

