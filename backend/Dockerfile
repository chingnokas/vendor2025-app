FROM node:18-slim

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Create environment file
RUN echo "DB_HOST=mariadb" > .env && \
    echo "DB_USER=root" >> .env && \
    echo "DB_PASSWORD=root" >> .env && \
    echo "DB_NAME=auth_db" >> .env && \
    echo "JWT_SECRET=your-secret-key" >> .env && \
    echo "PORT=3000" >> .env

EXPOSE 3000

CMD [ "npm", "start" ]
