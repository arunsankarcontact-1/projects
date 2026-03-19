FROM python:3.10-slim

WORKDIR /app
COPY app.py .

RUN pip install flask

ARG COLOR=blue
ENV COLOR=${COLOR}
ENV VERSION=1.0.0
ENV PORT=8080

EXPOSE 8080
CMD ["python", "app.py"]
