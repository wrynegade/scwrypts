'''
basic scwrypts.http client for linear

configured by setting the LINEAR__API_TOKEN option in the
scwrypts environment
'''

__all__ = [
        'request',
        'graphql',
        ]

from .client import request
from .graphql import graphql
