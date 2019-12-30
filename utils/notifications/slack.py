#/bin/python3

import argparse
import sys
import os
import json
import requests
from pygit2 import Repository
if os.getenv('DEBUG'):
    from pprint import pprint


def parse_git_info(directory=os.getcwd()):
    REPO = Repository(directory)
    HEAD = REPO.head
    COMMIT = REPO[HEAD.target]
    git_info = {}
    git_info['author_name'] = COMMIT.author.name
    git_info['author_email'] = COMMIT.author.email
    git_info['branch'] = HEAD.shorthand
    git_info['commit_hash'] = COMMIT.hex
    git_info['url'] = 'https://github.com/%s' % (os.getenv('GITHUB_REPOSITORY')
                                                 if os.getenv('GITHUB_REPOSITORY') else
                                                 REPO.remotes[0].url.split(':')[-1].split('.')[0])
    if os.getenv('DEBUG'):
        pprint(git_info)
    return git_info


def git_info_to_str(git_info, json=True):
    message = "\n".join(["*Branch:* {branch} (<{url}/tree/{branch}|On Github>)",
                         "*Commit:* `{commit_hash}` (<{url}/commit/{commit_hash}|On Github>)",
                         "*Author:* {author_name} <{author_email}>"])
    message = message.format(**git_info)
    if json:
        return {"type": "section", "text": {"type": "mrkdwn", "text": message}}
    else:
        return message


def post_to_slack(message):
    URL = 'https://hooks.slack.com/services/'
    SLACK_TOKEN = os.getenv('SLACK_TOKEN')
    if SLACK_TOKEN is None:
        print("##########################")
        print("# No Slack Token in ENV! #")
        print("# printing to stdout     #")
        print("##########################")
        print(message)
        sys.exit(0)

    response = requests.post(URL + SLACK_TOKEN, data=message.encode(),
                             headers={'Content-Type': 'application/json'})

    if response.status_code == 200:
        print("Message sent!")
        sys.exit(0)
    else:
        print("* Error sending message (status_code: {})".format(response.status_code))
        print(response.text)
        print("##### Message:")
        print(message)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("message", type=str, nargs='?',
                        help="Message to send to Slack channel")
    parser.add_argument("-f", "--file", type=str,
                        help="Read from file instead of argument or stdin")
    parser.add_argument("-d", "--debug", action='store_true',
                        default=False, help="Print message to stdout as well")
    parser.add_argument("--no-header", action='store_true',
                        default=False, help="Do not include header containing git information")
    args = parser.parse_args()

    message = ""
    if args.file:  # message provided as file
        with open(args.file, "r", encoding="utf-8") as f:
            message = f.read()
    elif args.message:  # message provided as argument
        message = args.message
    else:  # message piped in via stdin
        message = "".join(sys.stdin.readlines())

    header = None
    try:
        json_msg = json.loads(message)
    except json.JSONDecodeError as e:
        if args.debug:
            print(e)
        json_msg = {'blocks': [
            {'type': 'section', 'text': {'type': 'mrkdwn', 'text': message}}
        ]}

    if not args.no_header:
        git_info = parse_git_info()
        header = git_info_to_str(git_info)
        json_msg['blocks'].insert(0, {"type": "divider"})
        json_msg['blocks'].insert(0, header)

    final_msg = json.dumps(json_msg)

    if args.debug:
        print(final_msg)
        print()

    post_to_slack(final_msg)


if __name__ == "__main__":
    main()
