import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.tasks.crawler import sync_trigger_crawlers

if __name__ == "__main__":
    print("Testing crawler execution...")
    try:
        sync_trigger_crawlers()
        print("Crawler finished without raising top-level exceptions.")
    except Exception as e:
        import traceback
        traceback.print_exc()
