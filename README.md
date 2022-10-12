# Docker 带Java和Pyathon环境 镜像构建

## 测试方式

> 基于Springboot编写Demo来验证

python脚本在：src/main/resources/scripts/script.py，打印固定字符串和第一个入参
```python
import sys

print("xxx ")
print(sys.argv[1])
```

Java调用python的代码在：src/main/java/com/juhuan/javacallpythondemo/PythonController.java
从配置文件获取python脚本跟路径，拼接python命令后使用Runtime包调用。

```java
@RestController
public class PythonController {

    @Value("${scripts.root.path}")
    private String scriptsRootPath;

    @RequestMapping("/callPython")
    public String callPython() throws IOException {

        try {
            String         pythonFilePath = scriptsRootPath + "script.py";
            String         pythonParam    = "aaa";
            Process        proc           = Runtime.getRuntime().exec(String.format("python %s %s", pythonFilePath, pythonParam));
            BufferedReader in             = new BufferedReader(new InputStreamReader(proc.getInputStream()));

            String result = "";
            String line   = null;
            while ((line = in.readLine()) != null) {
                result = result + line + "\n";
            }
            in.close();
            proc.waitFor();
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            return e.getLocalizedMessage();
        }
    }
}
```

由于本机和docker容器中python脚本的位置不同，准备了两个配置文件

application-local.properties用于本机调试
```properties
spring.application.name=javaCallPythonDemo
server.port=8080

scripts.root.path=/Users/juhuan.wy/dev_temp/javaCallPythonDemo/src/main/resources/scripts/
```

application-prod.properties用于docker容器中运行
```properties
spring.application.name=javaCallPythonDemo
server.port=8080

scripts.root.path=/home/application/scripts/
```

`Dockerfile`内容见下一章节，有两种方式构建同时带Java和Python的容器环境

编译打包：`mvn clean install -Dmaven.test.skip=true`
打镜像：`docker build . -t juhuan/java_call_python_demo:0.0.2`
运行容器：`docker run -p 8080:8080 juhuan/java_call_python_demo:0.0.2`
验证URL：<http://localhost:8080/callPython>
![](https://cri-7t1ohedfaq5l9n1u-registry.oss-cn-shanghai.aliyuncs.com/i/202210121752830.png)

## 构建带Java和Python的容器环境

以下两种方法都验证成功，一比二构建快，二比一镜像小，各有优劣

### 方法一：COPY --from=python:3.6 / /

```docker
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
```

打完镜像1.3G
![](https://cri-7t1ohedfaq5l9n1u-registry.oss-cn-shanghai.aliyuncs.com/i/202210121709180.png)

### 方法二：依次构建Linux-Java-Python环境

```docker
### 1. Get Linux
FROM alpine:3.7

### 2. Get Java via the package manager
RUN apk update \
&& apk upgrade \
&& apk add --no-cache bash \
&& apk add --no-cache --virtual=build-dependencies unzip \
&& apk add --no-cache curl \
&& apk add --no-cache openjdk8-jre

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
```

打完镜像185.3 MB
![](https://cri-7t1ohedfaq5l9n1u-registry.oss-cn-shanghai.aliyuncs.com/i/202210121738266.png)