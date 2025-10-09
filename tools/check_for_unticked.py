import os
import sys

# directories to search and the file extensions to look for
ROOT_DIRS = ['code/', 'interface/', 'maps/']
FILE_EXTENSIONS = ['.dm', '.dme', '.dmf']

# list of files or directories to ignore
IGNORE_LIST = [
    'code/modules/unit_tests/'
]

# track for warnings later

non_utf8_files = []

def is_ignored(file_path):
    for ignore in IGNORE_LIST:
        if file_path.startswith(ignore):
            return True
    return False

def find_unticked_files(dme_file):
    unticked_files = []
    ticked_files = set()
    processed_files = set()

    def process_file(file_path, base_dir):
        if file_path in processed_files:
            return
        processed_files.add(file_path)

        try:
            try:
                f = open(file_path, 'r', encoding='utf-8')
                for line in f:
                    handle_line(line, base_dir)
            except UnicodeDecodeError:
                # track it
                if file_path not in non_utf8_files:
                    non_utf8_files.append(file_path)

                # fallback
                f = open(file_path, 'r', encoding='latin-1', errors='ignore')
                for line in f:
                    handle_line(line, base_dir)
            finally:
                f.close()
        except FileNotFoundError:
            print(f"Error: File '{file_path}' not found.")
            sys.exit(1)

    def handle_line(line, base_dir):
        line = line.strip()
        if line.startswith("#define") or line.startswith("//"):
            return
        if line.startswith("#include"):
            include_path = line.split('"')[1].replace('\\', '/')
            full_include_path = os.path.join(base_dir, include_path).replace('\\', '/')
            ticked_files.add(full_include_path)
            # recursiveness yippee
            if include_path.endswith('.dme') or include_path.endswith('.dm'):
                process_file(full_include_path, os.path.dirname(full_include_path))

    base_dir = os.path.dirname(dme_file)
    process_file(dme_file, base_dir)

    for root_dir in ROOT_DIRS:
        for dirpath, _, filenames in os.walk(root_dir):
            for filename in filenames:
                for extension in FILE_EXTENSIONS:
                    if filename.endswith(extension):
                        file_path = os.path.join(dirpath, filename).replace('\\', '/')
                        if not is_ignored(file_path) and file_path not in ticked_files:
                            unticked_files.append(file_path)

    return unticked_files

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python check_for_unticked.py <path_to_dme_file>")
        sys.exit(1)

    dme_file = sys.argv[1]
    unticked_files = find_unticked_files(dme_file)

    if unticked_files:
        print("Unticked files found:")
        for file in unticked_files:
            print(f" - {file}")
    else:
        print("No unticked files found.")

    if non_utf8_files:
        print("\nWARNING: The following files are not valid UTF-8:")
        for file in non_utf8_files:
            print(f" - {file}")

