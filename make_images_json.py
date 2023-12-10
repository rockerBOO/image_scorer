#!/usr/bin/env python

import json
from pathlib import Path
import argparse

# Set the directory you want to index here. "." is the current directory that you are in
IMAGE_DIR = "."
IMAGE_EXTS = [".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff", ".avif"]
IMAGE_JSON = "images.json"


def get_files(file_list, file_exts=[]):
    files = []

    for file in file_list.iterdir():
        if file.is_file() and file.suffix.lower() in file_exts:
            files.append(file)
        elif file.is_dir():
            files.extend(get_files(file, file_exts))

    return files


if __name__ == "__main__":
    argparser = argparse.ArgumentParser()

    argparser.add_argument("dir", help="Directory to get the images from")
    argparser.add_argument(
        "--exts",
        nargs="+",
        default=IMAGE_EXTS,
        help=f"Extensions for images. Default [{', '.join(IMAGE_EXTS)}]",
    )
    argparser.add_argument(
        "--json_file",
        default=IMAGE_JSON,
        help="JSON file to save the list of images to",
    )

    args = argparser.parse_args()

    cwd = Path(IMAGE_DIR)
    files = get_files(cwd, args.exts)

    with open(Path(args.json_file), "w") as f:
        json.dump([str(file) for file in files], f)
