#!/usr/bin/env python
from json import dumps

from py.lib.fzf import fzf, fzf_tail
from py.lib.http import directus
from py.lib.scwrypts import execute

from py.lib.scwrypts.exceptions import ImportedExecutableError

if __name__ != '__main__':
    raise ImportedExecutableError()

#####################################################################

def main(args, stream):
    if {None} == { args.collection, args.filters, args.fields }:
        args.interactive = True

    if args.interactive:
        args.generate_filters_prompt = True
        args.generate_fields_prompt = True

    collection = _get_or_select_collection(args)
    filters    = _get_or_select_filters(args, collection)
    fields     = _get_or_select_fields(args, collection)

    query = '&'.join([
        param for param in [
            fields,
            filters,
            ]
        if param
        ])

    endpoint = f'items/{collection}?{query}'

    response = directus.request('GET', endpoint)

    stream.writeline(dumps({
        **response.json(),
        'scwrypts_metadata': {
            'endpoint': endpoint,
            'repeat_with': f'scwrypts -n py/directus/get-items -- -c {collection} -f \'{query}\'',
            },
        }))

def _get_or_select_collection(args):
    collection = args.collection

    if collection is None:
        collection = fzf(
                prompt = 'select a collection',
                choices = directus.get_collections(),
                )

    if not collection:
        raise ValueError('collection required for query')

    return collection

def _get_or_select_filters(args, collection):
    filters = args.filters or ''

    if filters == '' and args.generate_filters_prompt:
        filters = '&'.join([
            f'filter[{filter}][' + (
                operator := fzf(
                    prompt = f'select operator for {filter}',
                    choices = directus.FILTER_OPERATORS,
                    )
                ) + ']=' + fzf_tail(prompt = f'filter[{filter}][{operator}]')

            for filter in fzf(
                prompt = 'select filter(s) [C^c to skip]',
                fzf_options = '--multi',
                force_list = True,
                choices = directus.get_fields(collection),
                )
            ])

    return filters

def _get_or_select_fields(args, collection):
    fields = args.fields or ''

    if fields == '' and args.generate_fields_prompt:
        fields = ','.join(fzf(
                prompt = 'select return field(s) [C^c to get all]',
                fzf_options = '--multi',
                choices = directus.get_fields(collection),
                force_list = True,
                ))

    if fields:
        fields = f'fields[]={fields}'

    return fields


#####################################################################
execute(main,
        description = 'interactive CLI to get data from directus',
        parse_args = [
            ( ['-c', '--collection'], {
                "dest"     : 'collection',
                "default"  : None,
                "help"     : 'the name of the collection',
                "required" : False,
                }),
            ( ['-f', '--filters'], {
                "dest"     : 'filters',
                "default"  : None,
                "help"     : 'as a URL-suffix, filters for the query',
                "required" : False,
                }),
            ( ['-d', '--fields'], {
                "dest"     : 'fields',
                "default"  : None,
                "help"     : 'comma-separated list of fields to include',
                "required" : False,
                }),
            ( ['-p', '--interactive-prompt'], {
                "action"   : 'store_true',
                "dest"     : 'interactive',
                "default"  : False,
                "help"     : 'interactively generate filter prompts; implied if no flags are provided',
                "required" : False,
                }),
            ( ['--prompt-filters'], {
                "action"   : 'store_true',
                "dest"     : 'generate_filters_prompt',
                "default"  : False,
                "help"     : '(superceded by -p) only generate filters interactively',
                "required" : False,
                }),
            ( ['--prompt-fields'], {
                "action"   : 'store_true',
                "dest"     : 'generate_fields_prompt',
                "default"  : False,
                "help"     : '(superceded by -p) only generate filters interactively',
                "required" : False,
                }),
            ]

        )
