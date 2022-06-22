from bpython import embed


def interactive(function):
    def main(*args, **kwargs):
        print('preparing interactive environment...')
        local_vars = function(*args, **kwargs)
        print('environment ready; user, GO! :)')
        embed(local_vars)

    return main
