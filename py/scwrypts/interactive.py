from bpython import embed


def interactive(function):
    def main(*args, **kwargs):
        local_vars = function(*args, **kwargs)
        embed(local_vars)

    return main
