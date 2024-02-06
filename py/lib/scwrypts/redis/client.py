from redis import StrictRedis

from scwrypts.env import getenv

CLIENT = None

def get_client():
    global CLIENT # pylint: disable=global-statement

    if CLIENT is None:
        print('getting redis client')
        CLIENT = StrictRedis(
                host = getenv('REDIS_HOST'),
                port = getenv('REDIS_PORT'),
                password = getenv('REDIS_AUTH', required=False),
                decode_responses = True,
                )

    return CLIENT
