FROM python:3.7

WORKDIR /usr/src/app

RUN apt-get update \
        && apt-get install -y gdal-bin  libgdal-dev \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

#COPY ./SkyBlock .
COPY ./build .


COPY ./Data /usr/src/Data

CMD [ "python", "./start_routeplanning_service.py" ]