#! /usr/bin/env python

import sys
import json


def main():
    schema = json.loads(sys.stdin.read())

    paths = schema['paths']

    for url, ops in paths.items():
        sys.stderr.write('url: {}\n'.format(url))
        if url.startswith('/api/v4/'):
            frags = url.split('/')

            if len(frags) > 5 and frags[4][0] == '{' and frags[5] != '-':
                prefix = '{}_{}'.format(frags[3], frags[5])
            else:
                prefix = frags[3]

            for v in ops.values():
                op_id = v['operationId']
                _, op = op_id.split('/')
                v['operationId'] = '{}/{}'.format(prefix, op)

    print(json.dumps(schema))


if __name__ == '__main__':
    main()
