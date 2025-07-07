#!/usr/bin/env python
"""
Compatibility wrapper to fix google_drive_downloader issue in PyTorch Geometric 1.4.1
"""

import os
import sys
import shutil

# Get the site-packages directory
site_packages = os.path.join(sys.prefix, 'lib', 'python3.8', 'site-packages')

# Create the wrapper content
wrapper_content = '''"""Compatibility wrapper for google_drive_downloader"""

from googledrivedownloader import download_file_from_google_drive

class GoogleDriveDownloader:
    @staticmethod
    def download_file_from_google_drive(file_id, dest_path, overwrite=False, unzip=False, showsize=False):
        """Wrapper for the function-based API"""
        download_file_from_google_drive(
            file_id=file_id, 
            dest_path=dest_path, 
            overwrite=overwrite,
            unzip=unzip,
            showsize=showsize
        )
'''

# Create google_drive_downloader directory if symlink exists
gdd_path = os.path.join(site_packages, 'google_drive_downloader')
if os.path.islink(gdd_path):
    os.unlink(gdd_path)

if not os.path.exists(gdd_path):
    os.makedirs(gdd_path)

# Write the wrapper
init_file = os.path.join(gdd_path, '__init__.py')
with open(init_file, 'w') as f:
    f.write(wrapper_content)

print("Compatibility wrapper created successfully!")
print(f"Location: {init_file}") 