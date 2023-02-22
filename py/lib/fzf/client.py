from pyfzf.pyfzf import FzfPrompt

FZF_PROMPT = None


def fzf( # pylint: disable=too-many-arguments
        choices=None,
        prompt=None,
        fzf_options='',
        delimiter='\n',
        return_type=str,
        force_list=False,
        ):
    global FZF_PROMPT # pylint: disable=global-statement

    if choices is None:
        choices = []

    if not isinstance(return_type, type):
        raise ValueError(f'return_type must be a valid python type; "{return_type}" is not a type')

    if FZF_PROMPT is None:
        FZF_PROMPT = FzfPrompt()

    options = ' '.join({
        '-i',
        '--layout=reverse',
        '--ansi',
        '--height=30%',
        f'--prompt "{prompt} : "' if prompt is not None else '',
        fzf_options,
        })

    selections = [
            return_type(selection)
            for selection in FZF_PROMPT.prompt(choices, options, delimiter)
            ]

    if not force_list:
        if len(selections) == 0:
            return None

        if len(selections) == 1:
            return selections[0]

    return selections


def fzf_tail(*args, **kwargs):
    return _fzf_print(*args, **kwargs)[-1]

def fzf_head(*args, **kwargs):
    return _fzf_print(*args, **kwargs)[0]

def _fzf_print(*args, fzf_options='', **kwargs):
    return fzf(
            *args,
            **kwargs,
            fzf_options = f'--print-query {fzf_options}',
            force_list = True,
            )
