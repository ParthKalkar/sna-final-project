#git clone https://github.com/InnoTutor/Frontend.git
#git clone https://github.com/InnoTutor/Backend.git

#Frontend--------------------------------------------
cd Frontend-main
docker build -t frontend:tutor .
#Database configuration-------------------------------

cd ../database
docker build -t mypostgres:tutor .

#docker run --name postgres -d -p 5432:5432 mypostgres:tutor 
#docker exec -it postgres bash 
#psql -U postgres innotutor < restore.sql
#psql -U postgres
#docker rm mypostgres:tutor
#docker rm mypostgres:tutor

#Backend----------------------------------------------

cd ../backend
docker build -t backend:tutor .	

#docker run --name backend -d -p 5432:5432 mypostgres:tutor 	
#docker run --name backend -it mypostgres:tutor 

#Run docker-compose-----------------------------------
cd ..
docker-compose build && docker-compose up

