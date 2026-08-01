import os

def get_size(start_path = '.'):
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(start_path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            # skip if it is symbolic link
            if not os.path.islink(fp):
                total_size += os.path.getsize(fp)
    return total_size

def print_sizes(path):
    sizes = []
    for item in os.listdir(path):
        item_path = os.path.join(path, item)
        if os.path.isdir(item_path):
            sizes.append((item, get_size(item_path)))
        else:
            sizes.append((item, os.path.getsize(item_path)))
            
    sizes.sort(key=lambda x: x[1], reverse=True)
    for item, size in sizes:
        print(f"{item}: {size / (1024 * 1024):.2f} MB")

if __name__ == '__main__':
    print_sizes(r'd:\harur\frontend')
