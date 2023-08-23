FROM python:3.10-slim-buster

WORKDIR /src

#COPY ./analytics/requirements.txt requirements.txt

COPY ./requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY ./ .

CMD python app.py

