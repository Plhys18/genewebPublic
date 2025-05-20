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
docker-compose up --build -d
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

### Adding Custom Data

To add your own data to the application, follow these steps:

#### 1. Prepare Data Files
- **FASTA Files**: Place prepared `.fasta` files in the `data/fasta_files/` subdirectory
- **Configuration Files**: Add corresponding `.json` files in the `data/jsons/` subdirectory

The JSON files should specify basic settings for each organism, including stages and other configuration parameters.

#### 2. Load New Data
After adding the files:
- Force reload the page or clear your browser cache
- The new organism should become available in the application

#### 3. Configure Private Dataset Access
If the dataset is configured as private, additional permissions must be set:

1. Navigate to the admin console at `localhost/admin`
2. Log in using the superuser account created during initial setup
3. Access the **Organism Access** section in the admin console
4. Create a new permission with the exact name matching your `.fasta` file (without extension)
5. Assign this permission to the appropriate user account
6. Log into the application with the authorized user account

Once these steps are completed, the private dataset will be accessible and ready for use within the application.

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

*Last updated: [19.5.2025]*
