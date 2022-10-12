FROM openjdk:slim
COPY --from=python:3.6 / /

VOLUME /tmp
ARG JAR_FILE

RUN mkdir -p /home/application/scripts/
COPY target/classes/scripts/* /home/application/scripts/
COPY target/javaCallPythonDemo-0.0.1-SNAPSHOT.jar /home/application/javaCallPythonDemo-0.0.1-SNAPSHOT.jar
#暴露端口
EXPOSE 8080
#执行命令java  -jar
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -jar /home/application/javaCallPythonDemo-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod ${0} ${@}"]
