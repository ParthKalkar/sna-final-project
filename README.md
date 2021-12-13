# SNA Project

## Contents
- [Introduction](#intro)
- [Solution plan](#sol)
- [Solution](#test)
- [Difficulties](#diff)
- [Video Demonstration](#video)
- [Results](#res)
- [Conclusion](#conc)
- [Contacts & Contribution](#cont)

## Introduction <a id="intro"> </a>
This is a project done for the final exam of *SNA* course taken in Block 2, Fall 2021 at Innopolis University

### Goal

* The goal of this project is to deploy a web application whose front-end is done in [Flutter](https://flutter.dev/), and back-end in [Spring-boot](https://spring.io/projects/spring-boot) 
* The application used for this task was created in the scope of another course named *Software Systems Analysis and Design* taken in Block 1, Fall 2021 at Innopolis University. 

To know more about the web-app - [Click Here](https://github.com/InnoTutor)

### Tasks
1. Create a *Docker Image* for front-end
2. Create a *Docker Image* for back-end
3. Create a *Docker Image* for database
4. Create a *Docker-Compose* file
5. Create a video demo


## Solution Plan <a id="sol"> </a>
### Methodology
- For depolyment we could use Docker Compose as well as a Virtual machine, so it was worth considering the difference between the two methods.

- A virtual machine emulates a whole isolated OS and requires as much resources as an OS does. It loads the kernel, its modules and all necessary libraries into memory before allocating resources for a user application.

- Docker, in turn, shares the kernel of the host machine with other containers. It takes no more memory than any other executable, which makes it lightweight.

- So, virtualization lets one run multiple OS on the hardware of a single physical server, while containerization lets one deploy multiple applications with the use of the same OS on a single virtual machine or server.

Therefore, it was more efficient for us to use *Docker*

### Execution plan
- We decided to create 3 separate *Dockerfiles* for back-end, front-end and database. 
- Followed by a *docker-compose* file for defining and running multi-containers. 
- We use a YAML file to configure application's services. 
- Then, with a single command, we create and start all the services from the given configurations.
- To make things simpler we created a *bashfile* which contains all the commands needed to build images, run containers, etc


## Solution <a id="test"> </a>

 ### Dockerizing the frontend
- To dockerize the frontend please make sure that you have ```docker``` installed. If not please install - [link](https://docs.docker.com/engine/install/ubuntu/)

 #### Creating the Dockerfile
 ```dockerfile
 # Install dependencies
FROM debian:latest AS build-env
ENV PROXY_API=$PROXY_API
RUN apt-get update 
RUN apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 python3 psmisc
RUN apt-get clean

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable flutter web
RUN flutter channel master
RUN flutter upgrade
RUN flutter config --enable-web

# Run flutter doctor
RUN flutter doctor -v

# Copy the app files to the container
COPY . /usr/local/bin/app

# Set the working directory to the app files within the container
WORKDIR /usr/local/bin/app

# Get App Dependencies
RUN flutter pub get
RUN flutter pub run build_runner build --delete-conflicting-outputs

# Build the app for the web
RUN flutter build web


# Document the exposed port
EXPOSE 4040

# Set the server startup script as executable
RUN ["chmod", "+x", "/usr/local/bin/app/server/server.sh"]

# Start the web server
CMD [ "bash", "/usr/local/bin/app/server/server.sh" ]
```
Hopefully, the comments on each line explain what's going on. 

To build the image we simply execute this command on the terminal. Make sure to run it from your projects root directory!
```$ docker build -t frontend:tutor .```


### Dockerizing the backend
- Similar to the frontend we can dockerize our backend.

#### Creating the dockerfile
```dockerfile
# Install dependencies
FROM ubuntu:latest AS git
RUN apt-get update && apt-get install -y git 
RUN git clone https://github.com/InnoTutor/Backend.git /Backend

# Move to working directory
WORKDIR /Backend/src/main/resources
RUN rm application.properties

# Copy from local machine
COPY application.properties application.properties

# Image for JDK
FROM openjdk:8-jdk-alpine

#  Expose port
EXPOSE 7357

#COPY Backend application
COPY --from=git Backend Backend

RUN apk add --no-cache curl tar bash procps

# Downloading and installing Maven

# 1- Define a constant with the version of maven you want to install
ARG MAVEN_VERSION=3.8.4         

# 2- Define a constant with the working directory
ARG USER_HOME_DIR="/root"

# 3- Define the SHA key to validate the maven download
ARG SHA=b4880fb7a3d81edd190a029440cdf17f308621af68475a4fe976296e71ff4a4b546dd6d8a58aaafba334d309cc11e638c52808a4b0e818fc0fd544226d952544

# 4- Define the URL where maven can be downloaded from
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

# 5- Create the directories, download maven, validate the download, install it, remove downloaded file and set links
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && echo "Downlaoding maven" \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "Unziping maven" \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && echo "Cleaning and setting links" \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# 6- Define environmental variables required by Maven, like Maven_Home directory and where the maven repo is located
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

WORKDIR /Backend

# Run Backend
CMD mvn clean install && java -jar target/innotutor_backend-0.0.1-SNAPSHOT.jar
```
 Hopefully, the comments on each line explain what's going on.

There is one big difference between the *frontend*- and the *backend*-dockerfile. The former contains code to build the application. If we make changes to the backend, we will need to build it again.

To build the image we simply execute this command on the terminal. Again, make sure to run it from your projects root directory!

```$ docker build -t backend:tutor .```

### Running it all at once
Now that we have everything we need we will use *docker-compose* to fire everything up. The docker compose tells docker which services (with which images) to start and also sets the environment variables. 

#### Creating docker-compose.yml 
```docker-compose
version: '2'
services:
  fronted:
    image: frontend:tutor
    ports:
      - "8081:4040"
  backend:
    healthcheck:
      timeout: 45s
      interval: 10s
      retries: 10
    image: backend:tutor
    depends_on:
     - db
    ports:
      - "7357:7357"
    environment:
      PROXY_API: http://backend:7357/
    
  db:
    image: mypostgres:tutor
    healthcheck:
      test: [ "CMD", "pg_isready", "-q", "-d", "postgres", "-U", "postgres" ]
      timeout: 45s
      interval: 10s
      retries: 10
    volumes:
      - ./mounts/db_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
```

To run the app execute:
```$ docker-compose build && docker-compose up```

The application should start and run successfully.

### Additionals
To make this whole process easier we made a `comands.sh`

```sh
#Frontend--------------------------------------------
cd Frontend-main
docker build -t frontend:tutor .

#Database configuration-------------------------------
cd ../database
docker build -t mypostgres:tutor .

#Backend----------------------------------------------
cd ../backend
docker build -t backend:tutor .	

#Run docker-compose-----------------------------------
cd ..
docker-compose build && docker-compose up
```

We just need to make this shell script executable and run:
```$ chmod +x comands.sh```
```$ ./comands.sh```

It will run all the necessary commands mentioned above

## Difficulties <a id="diff"> </a>
Following difficulties were faced in the whole process: 

1. Docker behaved differently on different machines and it raised some errors. When we tried to build docker-compose we have unsupported conf option healthcheck. 
*Solution* - In order to solve that problem, we installed the very same versions of docker, check docker-compose version and virtual machine as well as put the same settings.


2. When docker containers was tested, we was not able to connect frontend and backend. 
*Solution* - We check docker-compose file and project configuration. Finally, we set the correct ports to docker-compose file to solve this problem.
3. To run backend it required google credantials and database.
*Solution* - We add it on ```application.properties```. We meet the problem that google credentials was not installed correctly.
Project documentation has no detaild explanation of how create google credatitals. To overcome this problem of wrong google credentials we create our own google credentials.

## Video Demonstration <a id="video"> </a>

[Video link](https://drive.google.com/file/d/1ehFgO9LEUL_1O9_ix_97OVC5RffPxks0/view?usp=sharing)

## Results <a id="res"> </a>

1. Docker front-end image ![](https://i.imgur.com/HkWs6pe.png)
2. Docker back-end image 
![](https://i.imgur.com/ZcH3C1N.png)
3. Docker-Compose image
![](https://i.imgur.com/DZyu8Oz.jpg)![](https://i.imgur.com/hjzO5gK.jpg)
4. *InnoTutor* Main Page![](https://i.imgur.com/baazkXQ.png)

5. *InnoTutor* Services![](https://i.imgur.com/7XEa6sk.png)





## Conclusion<a id="conc"> </a>
We have been able to deploy a web application with the use of Docker Compose. As a result, we got definition of the services running with a single command that can spin everything up or tear it all down. Thus showing the tremendous power of *Docker*. 

Further we even discussed to make this process smoother by using an [ansible-notebook](https://www.ansible.com/) and make this whole process completely automatic.

## Contacts & Contribution <a id="cont"> </a>

* Parth Kalkar ([@ParthKalkar](https://t.me/ParthKalkar)),
    * created & managed github repository
    * created *Dockerfile* for front-end
    * wrote report

* Tasneem Toolba ([@TasneemToolba](https://t.me/taasneemtoolba)),
    * front-end development
    * handle back-end bugs
    * wrote report

* Daniil Shalagin ([@Danil Shalagin](https://t.me/FireBa11)),
    * created *Dockerfile* for back-end & Database
    * created *Docker-Compose* file 
    * testing

* Emil Khabibulin ([@EmilKhabibulin](https://t.me/@destinyhope)),
    * code development & deployment
    * testing
    * wrote report
