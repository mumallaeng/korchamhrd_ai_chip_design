"""PyInstaller hook for tkinterdnd2.

Based on the tkinterdnd2 project's official hook recommendation:
https://github.com/pmgagne/tkinterdnd2/blob/master/hook-tkinterdnd2.py
"""

from PyInstaller.utils.hooks import collect_data_files

datas = collect_data_files("tkinterdnd2")
