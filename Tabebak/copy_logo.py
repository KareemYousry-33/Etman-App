import os
import glob
import shutil

app_data_dir = r"C:\Users\smart\.gemini\antigravity\brain\1498a08a-496f-4ef5-adf4-93746f7f8535"
dest_path = r"d:\Etman_Work\Tabebak\assets\logo.png"

files = glob.glob(os.path.join(app_data_dir, "*.jpg")) + glob.glob(os.path.join(app_data_dir, "*.png"))
files.sort(key=os.path.getmtime, reverse=True)

if files:
    latest_file = files[0]
    print(f"Copying {latest_file} to {dest_path}")
    shutil.copy2(latest_file, dest_path)
else:
    print("No media files found")
