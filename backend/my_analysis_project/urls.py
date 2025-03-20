from django.contrib import admin
from django.urls import path, include, re_path
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from rest_framework import permissions

schema_view = get_schema_view(
    openapi.Info(
        title="My Analysis API",
        default_version='v1',
        terms_of_service="https://www.example.com/terms/",
        contact=openapi.Contact(email="support@example.com"),
        license=openapi.License(name="BSD License"),
        description="""
## **🔹 Full Program Workflow: Running an Analysis**
This API follows a structured workflow where users interact with organisms, configure analyses, and retrieve results.

---

### **1️⃣ Retrieve Available Organisms**  
📌 **Endpoint:** `GET /api/analysis/organisms/`  
- Users request a list of organisms from the server.  
- If the user is not authenticated, only public organisms are returned.  
- If the user is authenticated, both public and private organisms associated with the user’s group or personal access are included.

---

### **2️⃣ Retrieve Organism Details**  
📌 **Endpoint:** `POST /api/analysis/organism_details/`  
- After selecting an organism, the user requests detailed information.  
- This triggers the backend to load organism-related data, including available motifs, stages, and gene-related information.  

---

### **3️⃣ User Selects Motifs, Stages & Parameters**  
- Users configure their analysis by selecting motifs, stages, and additional parameters.  
- This step occurs entirely in the frontend before making a request to run the analysis.  

---

### **4️⃣ Run Analysis**  
📌 **Endpoint:** `POST /api/analysis/analyze/`  
- The frontend sends the selected organism, motifs, stages, and parameters to the backend.  
- The backend validates the input, ensuring all required information is present and that the user has the necessary permissions.  
- If everything is valid, the backend runs the analysis.  
- If the user is authenticated, the results are also stored in the database.  

---

### **5️⃣ View Analysis History**  
📌 **Endpoint:** `GET /api/analysis/history/`  
- If authenticated, the user can request a list of their previous analyses.  
- This provides metadata about past analyses, such as names and timestamps.  

---

### **6️⃣ Retrieve Specific Analysis Results**  
📌 **Endpoint:** `GET /api/analysis/history/{id}/`  
- If authenticated, the user can request detailed results of a specific past analysis by providing its ID.  
- This step is entirely optional and can be done separately from running a new analysis.  
""",
    ),
    public=True,
    permission_classes=([permissions.AllowAny]),
    url=" https://golembackend.duckdns.org ",
)


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('auth_app.urls')),
    path('api/analysis/', include('my_analysis_project.analysis.urls')),

    # Swagger UI and Redoc
    path('api/docs/', schema_view.with_ui('swagger', cache_timeout=0), name='swagger-ui'),
    path('api/redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='redoc'),
    re_path(r'^swagger(?P<format>\.json|\.yaml)$', schema_view.without_ui(cache_timeout=0), name='schema-json'),
]
