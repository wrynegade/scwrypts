class MissingVariableError(Exception):
    def init(self, name):
        super().__init__(f'Missing required environment variable "{name}"')
