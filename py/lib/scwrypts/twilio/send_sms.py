from json import dumps
from time import sleep

from .client import get_client


def send_sms(to, from_, body, max_char_count=300, stream=None):
    '''
    abstraction for twilio.client.messages.create which will break
    messages into multi-part SMS rather than throwing an error or
    requiring the use of MMS data

    @param to               messages.create parameter
    @param from_            messages.create parameter
    @param body             messages.create parameter
    @param max_char_count   1 ≤ N ≤ 1500 (default 300)
    @param stream           used to report success/failure (optional)

    @return   a list of twilio MessageInstance objects
    '''
    client = get_client()
    messages = []

    max_char_count = max(1, min(max_char_count, 1500))

    total_sms_parts = 1 + len(body) // max_char_count
    contains_multiple_parts = total_sms_parts > 1

    for i in range(0, len(body), max_char_count):
        msg_body = body[i:i+max_char_count]
        current_part = 1 + i // max_char_count

        if contains_multiple_parts:
            msg_body = f'{current_part}/{total_sms_parts}\n{msg_body}'

        message = client.messages.create(
                to = to,
                from_ = from_,
                body = msg_body,
                )

        messages.append(message)

        if stream is not None:
            stream.writeline(
                    dumps({
                        'sid': message.sid,
                        'to': to,
                        'from': from_,
                        'body': msg_body,
                        })
                    )

        if contains_multiple_parts:
            sleep(2 if max_char_count <= 500 else 5)

    return messages
