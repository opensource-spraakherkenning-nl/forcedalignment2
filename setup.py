#! /usr/bin/env python
# -*- coding: utf8 -*-


import os
import io
from setuptools import setup


def getreadme():
    for fname in ('README.rst','README.md', 'README'):
        if os.path.exists(fname):
            return io.open(os.path.join(os.path.dirname(__file__), fname),'r',encoding='utf-8').read()
    return ""

setup(
    name = "forcedalignment2",
    version = "0.1", #make sure SYSTEM_VERSION in your service configuration is set to the same value!
    author = "Louis ten Bosch", #adapt this
    description = ("Forced Alignment 2"),
    license = "GPL",
    keywords = "clam webservice rest nlp computational_linguistics rest",
    url = "https://gitlab.science.ru.nl/ltenbosch/forcedalignment2", #update this!
    packages=['forcedalignment2'],
    long_description=getreadme(),
    classifiers=[
        "Development Status :: 5 - Production/Stable", #you may want to downgrade this
        "Topic :: Internet :: WWW/HTTP :: WSGI :: Application",
        "Topic :: Text Processing :: Linguistic", #check and remove or change if not relevant
        "Programming Language :: Python :: 3.4", #3.0, 3.1 and 3.2 are not supported by flask/CLAM
        "Programming Language :: Python :: 3.5",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Operating System :: POSIX",
        "Intended Audience :: Developers",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: GNU General Public License v3 (GPLv3)",
    ],
    package_data = {'forcedalignment2':['*.wsgi','*.yml','*.sh', '*.fst', '*.perl', '*.wav', '*.tg', '*.ctm', '*.ali', '*.aliphw2', '*.oov'] },
    include_package_data=True,
    install_requires=['CLAM >= 3.0']
)
