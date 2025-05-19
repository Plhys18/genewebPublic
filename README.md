# GeneWeb - Public Repository

> **Bachelor's Thesis Appendix**  
> This is the public version of the GeneWeb codebase, created specifically for the appendix of a bachelor's thesis. All private data has been removed for security and privacy purposes.

## ⚠️ Important Notice

**REUSE IS FORBIDDEN**  
This repository is provided for **VIEW-ONLY** purposes. No part of this code may be used, modified, or redistributed without explicit permission.

---

## Local Development Setup

Follow these steps to run the application locally for development purposes:

### Prerequisites

Before you begin, ensure you have the following installed:

- **Python 3.11** (required)
- **Docker** and **Docker Compose**
- **Google RE2 library** (precompiled with all dependencies)

### Step-by-Step Installation

#### 1. Clone and Switch Branch
```bash
git clone <repository-url>
cd <repository-name>
git checkout JakubBranch
```

#### 2. Setup SSL Certificate
```bash
./prepare-dev-certs.sh
```
*This script creates a self-signed certificate for local development.*

#### 3. Verify Dependencies
Ensure all prerequisites are properly installed:
- Python 3.11
- Google RE2 library
- Docker & Docker Compose

#### 4. Build and Start Services
```bash
cd genweb
docker-compose up --build
```

#### 5. Access the Application
- Open your browser and navigate to `localhost`
- ⚠️ **Note**: Your browser will display a security warning due to the self-signed certificate. This is expected behavior in development.

### Initial Configuration

#### Create Admin User
The database starts empty, so you'll need to create an admin user manually:

```bash
# Start containers in detached mode
docker-compose up --build -d

# Create superuser
docker-compose exec backend python manage.py createsuperuser
```

#### Access Admin Console
1. Navigate to `localhost/admin`
2. Log in with your newly created admin credentials
3. Add additional users and assign privileges/organisms as needed

---

## Data Management

> **⚠️ No Data Available**  
> Since this is a public fork with all private data removed, no genealogical data will be displayed. The application structure is intact for demonstration purposes only.

All data is mounted from the `data` folder, which remains empty in this public version.

---

## Architecture

- **Backend**: Python-based application running in Docker
- **Frontend**: Web interface accessible via browser
- **Database**: Clean initialization (no pre-loaded data)
- **SSL**: Self-signed certificates for local development

---

## Development Notes

- This setup is intended for development and demonstration purposes only
- Production deployment would require additional security configurations
- SSL certificates should be properly signed for production use

---

## Support

This repository is provided as-is for academic purposes. For questions related to the bachelor's thesis, please contact the author through appropriate academic channels.

---

*Last updated: [Current Date]*
