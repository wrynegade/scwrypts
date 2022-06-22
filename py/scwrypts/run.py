from os import getenv
from pathlib import Path
from subprocess import run as subprocess_run


def run(scwrypt_name, *args):
    DEPTH = int(getenv('SUBSCWRYPT', '0'))
    DEPTH += 1

    print(f'\n {"--"*DEPTH} ({DEPTH}) BEGIN SUBSCWRYPT : {Path(scwrypt_name).name}')
    subprocess_run(
        f'SUBSCWRYPT={DEPTH} {Path(__file__).parents[2] / "scwrypts"} {scwrypt_name} -- {" ".join([str(x) for x in args])}',
        shell=True,
        executable='/bin/zsh',
        )

    print(f' {"--"*DEPTH} ({DEPTH}) END SUBSCWRYPT   : {Path(scwrypt_name).name}\n')
