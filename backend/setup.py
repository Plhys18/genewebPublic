from setuptools import setup, find_packages

setup(
    name="my_analysis_backend",
    version="0.1.0",
    description="Backend Python code",
    packages=find_packages(
        where=".",
        exclude=[".venv", "env", "data", "tests*", "docs*"]
    ),
    python_requires=">=3.10",
    install_requires=[],
)
