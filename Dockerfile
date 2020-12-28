FROM alpine:edge
MAINTAINER n3k1 <docker@n3k1.de>
LABEL maintainer="n3k1 <docker@n3k1.de>"

EXPOSE 80\tcp 443\tcp
ENV MUMBLE_SERVER=mumble.aventer.biz:64738

COPY ./ /home/node

RUN echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
	apk add --no-cache git nodejs npm tini websockify && \
	adduser -D -g 1001 -u 1001 -h /home/node node && \
	mkdir -p /home/node && \
	mkdir -p /home/node/.npm-global && \
	mkdir -p /home/node/app && \
	chown -R node: /home/node && \
	chmod -v 775 /home/node/webmur.crt \
		/home/node/webmur.key

USER node

ENV PATH=/home/node/.npm-global/bin:$PATH
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global

RUN cd /home/node && \
	npm install && \
	npm run build 

USER root

RUN apk del gcc git

USER node

ENTRYPOINT ["/sbin/tini", "--"]
CMD websockify --ssl-target --web=/home/node/dist --log-file=/home/node/web.log -D 80 "$MUMBLE_SERVER" && \
	websockify --ssl-target --web=/home/node/dist --log-file=/home/node/webssl.log --cert=/home/node/webmur.crt --key=/home/node/webmur.key 443 "$MUMBLE_SERVER"