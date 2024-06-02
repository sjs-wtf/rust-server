from rcon.source import Client

with Client('127.0.0.1', 28082, passwd='hungry4lemongrass') as client:
    response = client.run('server.fps')

print(response)