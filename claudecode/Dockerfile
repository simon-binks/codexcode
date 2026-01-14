ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    nodejs \
    npm \
    python3 \
    py3-pip \
    ttyd \
    openssh-client \
    ripgrep

# Create claude user home directory
RUN mkdir -p /root/.claude /root/.local/bin

# Install Claude Code via npm (native binary not available for Alpine)
RUN npm install -g @anthropic-ai/claude-code

# Install hass-mcp for Home Assistant integration
RUN pip3 install --no-cache-dir --break-system-packages homeassistant-mcp

# Set up PATH
ENV PATH="/root/.local/bin:${PATH}"

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

# Set working directory
WORKDIR /homeassistant

# Expose ttyd port
EXPOSE 7681

CMD [ "/run.sh" ]
