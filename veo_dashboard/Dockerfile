FROM node:20-slim

WORKDIR /app

# Copy manifests first for layer caching
COPY package*.json ./

# Remove the macOS-specific rollup binary before installing.
# npm will pull the correct Linux binary automatically.
RUN npm pkg delete dependencies.@rollup/rollup-darwin-x64 && \
    npm install

COPY . .

EXPOSE 3000

# At runtime:
#  1. Pull query results from DuckDB into Evidence's cache  (needs /db volume)
#  2. Build the static site
#  3. Serve it on port 3000
#
# EVIDENCE_SOURCE__VEO__FILENAME overrides the filename in sources/veo/connection.yaml
CMD ["sh", "-c", "npm run sources && npm run build && HOST=0.0.0.0 npm run preview"]
