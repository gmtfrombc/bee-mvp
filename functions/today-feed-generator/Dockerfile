# Use the official Deno runtime as a parent image
FROM denoland/deno:1.42.4

# Set the working directory
WORKDIR /app

# Copy the source code
COPY . .

# Cache the dependencies
RUN deno cache index.ts

# Expose the port
EXPOSE 8080

# Set environment variables
ENV PORT=8080

# Run the application
CMD ["run", "--allow-net", "--allow-env", "--allow-read", "index.ts"] 