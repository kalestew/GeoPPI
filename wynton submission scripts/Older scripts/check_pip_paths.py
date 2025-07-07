#!/usr/bin/env python
"""Check where pip and Python are finding packages"""

import sys
import site
import os

print("Python Information:")
print(f"Python executable: {sys.executable}")
print(f"Python version: {sys.version}")
print(f"User site packages enabled: {not sys.flags.no_user_site}")
print()

print("Python Path:")
for i, path in enumerate(sys.path):
    print(f"  {i}: {path}")
print()

print("Site Packages:")
print(f"Site packages: {site.getsitepackages()}")
print(f"User site: {site.getusersitepackages()}")
print(f"User base: {site.getuserbase()}")
print()

print("Environment Variables:")
print(f"PYTHONPATH: {os.environ.get('PYTHONPATH', 'Not set')}")
print(f"PYTHONNOUSERSITE: {os.environ.get('PYTHONNOUSERSITE', 'Not set')}")
print()

# Check if problem packages are importable
problem_packages = ['anndata', 'kb_python', 'loompy', 'scanpy', 'umap']
print("Checking problem packages:")
for pkg in problem_packages:
    try:
        mod = __import__(pkg.replace('_', '-') if '_' in pkg else pkg)
        print(f"  ✓ {pkg}: Found at {mod.__file__}")
    except ImportError:
        print(f"  ✗ {pkg}: Not found") 