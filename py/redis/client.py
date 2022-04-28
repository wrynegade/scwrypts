from redis import StrictRedis

from py.scwrypts import getenv


class RedisClient(StrictRedis):
    def __init__(self):
        super().__init__(
                host = getenv('REDIS_HOST'),
                port = getenv('REDIS_PORT'),
                password = getenv('REDIS_AUTH'),
                decode_responses = True,
                )

Client = RedisClient()
