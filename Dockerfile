#use an official node.js runtime as the base image
FROM node:14-alpine

#set the working directory inside the container
WORKDIR /usr/src/app

#copy package.json and package-lock.json dependency files to the container
COPY package.json ./

#install dependencies
RUN npm install

# copy the app files to the container
COPY dist/ ./dist/
COPY server.js ./

# specify the port on which the server is to be run
ENV PORT=3000

#expose the port on which the app will run
EXPOSE 3000

#set the command to run the app when the container starts
CMD [ "node", "server.js" ]