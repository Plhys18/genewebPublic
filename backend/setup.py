from setuptools import setup, find_packages

setup(
    name="my_analysis_backend",
    version="0.1.0",
    description="Backend Python code for motif analysis, converted from Dart.",
    packages=find_packages(where="lib"),
    package_dir={"": "lib"},
    python_requires=">=3.7",
    install_requires=[],
)
