# ForcedAlignment2

A forced alignment webservice; aligns an audio file with its transcription.
Builds upon [kaldi](http//kaldi-asr.org) and [phonetisaurus](https://github.com/AdolfVonKleist/Phonetisaurus).

## Installation

For end-users and hosting partners, we provide a container image that ships with a web interface based on
[CLAM](https://proycon.github.io/clam/). Through this application some of our pretrained models are directly available
for end-users. You can pull a prebuilt image from the Docker Hub registry using docker as follows:

```
$ docker pull proycon/forcedalignment2
```

You can also build the container image yourself using a tool like ``docker build``, which is the recommended option if
you are deploying this in your own infrastructure. In that case will want set some of the environment variables defined
in ``Dockerfile``.

Run the container as follows:

```
$ docker run -v /path/to/your/data:/data -p 8080:80 proycon/forcedalignment2
```

Ensure that the directory you pass is writable.

Assuming you run locally, the web interface can then be accessed on ``http://127.0.0.1:8080/``.

