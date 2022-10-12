#FROM openjdk:slim
#COPY --from=python:3.6 / /
#
#VOLUME /tmp
#ARG JAR_FILE
#
#RUN mkdir -p /home/application/scripts/
#COPY target/classes/scripts/* /home/application/scripts/
#COPY target/javaCallPythonDemo-0.0.1-SNAPSHOT.jar /home/application/javaCallPythonDemo-0.0.1-SNAPSHOT.jar
##暴露端口
#EXPOSE 8080
##执行命令java  -jar
#ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -jar /home/application/javaCallPythonDemo-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod ${0} ${@}"]

### 1. Get Linux
FROM alpine:3.7

### 2. Get Java via the package manager
RUN apk update \
&& apk upgrade \
&& apk add --no-cache bash \
&& apk add --no-cache --virtual=build-dependencies unzip \
&& apk add --no-cache curl \
&& apk add --no-cache openjdk8-jre \
&& apk add --no-cache nss


### 3. Get Python, PIP

RUN apk add --no-cache python3 \
&& python3 -m ensurepip \
&& pip3 install --upgrade pip setuptools \
&& rm -r /usr/lib/python*/ensurepip && \
if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
rm -r /root/.cache

### Get Flask for the app
RUN pip install --trusted-host pypi.python.org flask

####
#### OPTIONAL : 4. SET JAVA_HOME environment variable, uncomment the line below if you need it

#ENV JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk"

####

RUN mkdir -p /home/application/scripts/
COPY target/classes/scripts/* /home/application/scripts/
COPY target/javaCallPythonDemo-0.0.1-SNAPSHOT.jar /home/application/javaCallPythonDemo-0.0.1-SNAPSHOT.jar
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -jar /home/application/javaCallPythonDemo-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod ${0} ${@}"]