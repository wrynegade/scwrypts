'''
basic scwrypts.http client for directus

configured by setting DIRECTUS__BASE_URL and DIRECTUS__API_TOKEN in
scwrypts environment
'''

__all__ = [
        'request',
        'graphql',
        'get_collections',
        'get_fields',
        'FILTER_OPERATORS',
        ]

from .client import request
from .graphql import graphql
from .collections import get_collections
from .fields import get_fields

FILTER_OPERATORS = {
        '_eq',
        '_neq',
        '_lt',
        '_lte',
        '_gt',
        '_gte',
        '_in',
        '_nin',
        '_null',
        '_nnull',
        '_contains',
        '_ncontains',
        '_starts_with',
        '_ends_with',
        '_nends_with',
        '_between',
        '_nbetween',
        '_empty',
        '_nempty',
        '_intersects',
        '_nintersects',
        '_intersects_bbox',
        '_nintersects_bbox',
        }
