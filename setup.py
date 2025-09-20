from setuptools import setup, find_packages
import os

# Read the README file
this_directory = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(this_directory, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name="triton-windows",
    version="3.4.0",
    author="Triton Developers",
    author_email="triton-dev@lists.lfai.foundation",
    description="Triton is a language and compiler for parallel programming",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/openai/triton",
    package_dir={'': 'python'},
    packages=find_packages(where='python', include=['triton', 'triton.*']),
    include_package_data=True,
    package_data={
        'triton': [
            '_C/libtriton.pyd',
            'backends/nvidia/**/*',
        ],
    },
    entry_points={
        'triton.backends': [
            'nvidia = triton.backends.nvidia',
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
    python_requires=">=3.8",
    install_requires=[
        "torch>=2.0.0",
    ],
)