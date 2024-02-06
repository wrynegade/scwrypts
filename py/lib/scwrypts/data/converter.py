import csv
import json
import yaml


def convert(input_stream, input_type, output_stream, output_type):
    data = convert_input(input_stream, input_type)
    write_output(output_stream, output_type, data)


def convert_input(stream, input_type):
    supported_input_types  = {'csv', 'json', 'yaml'}

    if input_type not in supported_input_types:
        raise ValueError(f'input_type "{input_type}" not supported; must be one of {supported_input_types}')

    return {
            'csv':  _read_csv,
            'json': _read_json,
            'yaml': _read_yaml,
            }[input_type](stream)


def write_output(stream, output_type, data):
    supported_output_types = {'csv', 'json', 'yaml'}

    if output_type not in supported_output_types:
        raise ValueError(f'output_type "{output_type}" not supported; must be one of {supported_output_types}')

    return {
            'csv':  _write_csv,
            'json': _write_json,
            'yaml': _write_yaml,
            }[output_type](stream, data)


#####################################################################

def _read_csv(stream):
    return [dict(line) for line in csv.DictReader(stream)]

def _write_csv(stream, data):
    writer = csv.DictWriter(stream, fieldnames=list({
        key
        for dictionary in data
        for key in dictionary.keys()
        }))

    writer.writeheader()

    for value in data:
        writer.writerow(value)

#####################################################################

def _read_json(stream):
    data = json.loads(stream.read())
    return data if isinstance(data, list) else [data]

def _write_json(stream, data):
    stream.write(json.dumps(data))

#####################################################################

def _read_yaml(stream):
    data = yaml.safe_load(stream)
    return data if isinstance(data, list) else [data]

def _write_yaml(stream, data):
    yaml.dump(data, stream, default_flow_style=False)
