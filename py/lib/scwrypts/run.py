from os import getenv
from pathlib import Path
from subprocess import run as subprocess_run


def run(scwrypt_name, *args):
    DEPTH = int(getenv('SUBSCWRYPT', '0'))
    DEPTH += 1

    SCWRYPTS_EXE = Path(__file__).parents[3] / 'scwrypts'
    ARGS = ' '.join([str(x) for x in args])
    print(f'SUBSCWRYPT={DEPTH} {SCWRYPTS_EXE} {scwrypt_name} -- {ARGS}')

    print(f'\n {"--"*DEPTH} ({DEPTH}) BEGIN SUBSCWRYPT : {Path(scwrypt_name).name}')
    subprocess_run(
        f'SUBSCWRYPT={DEPTH} {SCWRYPTS_EXE} {scwrypt_name} -- {ARGS}',
        shell=True,
        executable='/bin/zsh',
        check=False,
        )

    print(f' {"--"*DEPTH} ({DEPTH}) END SUBSCWRYPT   : {Path(scwrypt_name).name}\n')
