'''
loads the twilio.rest.Client by referencing TWILIO__API_KEY,
TWILIO__API_SECRET, and TWILIO__ACCOUNT_SID in your scwrypts
environment
'''

__all__ = [
        'get_client',
        'send_sms',
        ]

from .client import get_client
from .send_sms import send_sms
