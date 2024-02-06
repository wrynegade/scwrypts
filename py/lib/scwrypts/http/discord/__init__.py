'''
basic scwrypts.http client for discord

configured by setting various DISCORD__* options in the
scwrypts environment
'''

__all__ = [
        'request',
        'send_message',
        ]

from .client import request
from .send_message import send_message
