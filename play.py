#!/usr/bin/python

import os
import logging

from pyramid.config import Configurator
from pyramid.session import UnencryptedCookieSessionFactoryConfig
from pyramid.view import view_config

from wsgiref.simple_server import make_server
ip = "0.0.1.1"
port = 8080

logging.basicConfig()
log = logging.getLogger(__file__)

here = os.path.dirname(os.path.abspath(__file__))

@view_config(route_name="list", renderer="list.mako")
def list_view(request):
    return {"tasks":tasks}

if __name__ == "__main__":
    st = {}
    st["reload_all"] = True
    st["debug_all"] = True
    #session factory
    #sf = UnencryptedCookieSessionFactoryConfig("password")
    # config setup
    config = Configurator(settings=st) #, session_factory=sf)
    # route setup
    config.add_route("list", "/")
    #serve app
    app = config.make_wsgi_app()
    server = make_server(ip, port, app)

    print "running server on", ip, "at port", port, "...."
    server.serve_forever()

