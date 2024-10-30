from setuptools import setup, find_packages

setup(
    name="goldenpond",
    version="0.2.0",
    author="Phil Jones",
    author_email="interstar@gmail.com",
    description="A Python library for interpreting the GoldenPond chord-progression DSL",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/interstar/golden-pond",
    packages=find_packages(),
    license="GPL-3.0-or-later",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: GNU General Public License v3 (GPLv3)",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
)
