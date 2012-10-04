#!/usr/bin/python

import os
import logging

from pyramid.config import Configurator
from pyramid.session import UnencryptedCookieSessionFactoryConfig
from pyramid.view import view_config
from pyramid.response import Response

from wsgiref.simple_server import make_server

ip = "0.0.0.0"
port = 8080

#logging.basicConfig()
#log = logging.getLogger(__file__)

here = os.path.dirname(os.path.abspath(__file__))

@view_config(route_name="list", renderer="list.mako")
def list_view(request):
    return {"tasks":tasks}

def hello_world(request):
    return Response("Hello %(name)s!" % request.matchdict)

if __name__ == "__main__":
    #st = {}
    #st["reload_all"] = True
    #st["debug_all"] = True
    #session factory
    #sf = UnencryptedCookieSessionFactoryConfig("password")
    # config setup
    config = Configurator() #settings=st) #, session_factory=sf)
    # route setup
    config.add_route("hello", "/hello/{name}")
    config.add_view(hello_world, route_name="hello")
    #serve app
    app = config.make_wsgi_app()
    server = make_server(ip, port, app)

    print "running server on", ip, "at port", port, "...."
    server.serve_forever()

