from twilio.rest import Client

from scwrypts.env import getenv

CLIENT = None

def get_client():
    global CLIENT # pylint: disable=global-statement

    if CLIENT is None:
        print('loading client')
        CLIENT = Client(
                username = getenv('TWILIO__API_KEY'),
                password = getenv('TWILIO__API_SECRET'),
                account_sid = getenv('TWILIO__ACCOUNT_SID'),
                )

    return CLIENT
