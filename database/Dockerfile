#DB
FROM ubuntu:latest AS git
RUN apt-get update && apt-get install -y git 
RUN git clone https://github.com/InnoTutor/Backend.git /Backend

FROM postgres:latest

#COPY restore.sql /docker-entrypoint-initdb.d/
COPY --from=git /Backend/restore.sql /docker-entrypoint-initdb.d/

ENV POSTGRES_PASSWORD=root
ENV POSTGRES_DB=innotutor
ENV POSTGRES_HOST_AUTH_METHOD=trust

