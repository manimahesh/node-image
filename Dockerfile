# Stage 1: Build Stage
# Use a slim Node.js base image for building/installing dependencies
FROM node:20-slim AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker caching
# This ensures that npm install is only re-run if dependencies change.
COPY package*.json ./

# Install project dependencies
RUN npm install --production

# Copy the rest of the application code
COPY . .

# ---

# Stage 2: Production Stage (Smaller Image)
# Use a minimal, highly optimized image for the final production container
FROM node:20-alpine

# Set the working directory
WORKDIR /app

# Copy only the necessary files (node_modules and app code) from the builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/server.js .

# The application runs on port 80 (as defined in your server.js)
EXPOSE 80

# Set the default command to run the server
CMD ["node", "server.js"]
