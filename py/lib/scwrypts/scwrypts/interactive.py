from bpython import embed


def interactive(variable_descriptions):
    '''
    main() decorator to drop to interactive python environment upon completion
    '''
    def outer(function):

        def inner(*args, **kwargs):

            print('\npreparing interactive environment...\n')

            local_vars = function(*args, **kwargs)

            print('\n\n'.join([
                f'>>> {x}' for x in variable_descriptions
                ]))
            print('\nenvironment ready; user, GO! :)\n')

            embed(local_vars)

        return inner

    return outer
