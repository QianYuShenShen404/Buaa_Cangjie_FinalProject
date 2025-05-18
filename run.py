import sys
sys.stdout.reconfigure(encoding='utf-8', line_buffering=True)
import os
import subprocess
import webbrowser

# 获取当前工作目录
current_dir = os.getcwd()

# 运行 main.exe
main_exe_path = os.path.join(current_dir, 'target', 'release', 'bin', 'main.exe')
if os.path.exists(main_exe_path):
    print(f"Running {main_exe_path}...")
    process = subprocess.Popen(main_exe_path, cwd=current_dir)
    # 等待程序执行完毕
else:
    print(f"Error: {main_exe_path} does not exist.")
    exit(1)

# 打开 index.html
index_html_path = os.path.join(current_dir, 'src', 'website', 'index.html')
if os.path.exists(index_html_path):
    print(f"Opening {index_html_path} in the default browser...")
    webbrowser.open(f'file://{index_html_path}')
else:
    print(f"Error: {index_html_path} does not exist.")

input("Press Enter to exit...")