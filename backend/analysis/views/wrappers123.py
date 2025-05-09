from functools import wraps


def ensure_auth(func):
    @wraps(func)
    def wrapper(request, *args, **kwargs):
        return func(request, *args, **kwargs)
    return wrapper