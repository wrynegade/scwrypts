'''
scwrypts meta-configuration

provides a helpful three ways to run "scwrypts"

 'scwrypts' is an agnostic, top-level executor allowing any scwrypt to be called from python workflows

 'execute' is the default context set-up for python-based scwrypts

 'interactive' is a context set-up for interactive, python-based scwrypts
   after execution, you are dropped in a bpython shell with all the variables
   configured during main() execution
'''

__all__ = [
        'scwrypts',
        'execute',
        'interactive',
        ]

from .scwrypts import scwrypts
from .execute import execute
from .interactive import interactive
