# ---------- Stage 1: Builder ----------
FROM python:3.10-slim AS builder

WORKDIR /install

# Prevent python from writing pyc files
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY app/requirements.txt .

# Install dependencies into a separate folder
RUN pip install --user -r requirements.txt


# ---------- Stage 2: Runtime ----------
FROM python:3.10-slim

WORKDIR /app

# Copy installed python packages from builder
COPY --from=builder /root/.local /root/.local

# Add path
ENV PATH=/root/.local/bin:$PATH

# Copy application code
COPY app/ .

# Expose application port
EXPOSE 5000

# Run application
CMD ["python", "app.py"]
