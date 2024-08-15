#!/usr/bin/python3
from os import environ, getenv, getuid
from os.path import abspath
from pathlib import Path
from shutil import copytree, ignore_patterns
from subprocess import run

match getenv("CHEZMOI_COMMAND"):
    case "apply":
        if getuid() != 0:
            run(["sudo", "-E", "/usr/bin/python3", __file__])
            exit()
        copytree(Path(getenv("CHEZMOI_WORKING_TREE")) / "root", "/", ignore=ignore_patterns("*~"), dirs_exist_ok=True)
    case "add":
        pass
    case _:
        print(environ)
#for path in getenv("CHEZMOI_ARGS", "").split()[2:]:
#   print(abspath(Path(abspath(path)) / ".."))
