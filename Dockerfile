# sudo docker build -t finddocker .
# sudo docker run -it -p 18003:8003 -p 11883:1883 -v /path/to/host/data/folder:/data finddocker bash
FROM ubuntu:16.04

# Get basics
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y golang git wget curl vim
RUN mkdir /usr/local/work
ENV GOPATH /usr/local/work

# Add Python stuff
RUN apt-get install -y python3 python3-dev python3-pip
RUN apt-get install -y python3-scipy python3-numpy
RUN python3 -m pip install scikit-learn

# Install SVM
WORKDIR "/tmp"
RUN wget http://www.csie.ntu.edu.tw/~cjlin/cgi-bin/libsvm.cgi?+http://www.csie.ntu.edu.tw/~cjlin/libsvm+tar.gz -O libsvm.tar.gz
RUN tar -xvzf libsvm.tar.gz
RUN mv libsvm-*/* ./
RUN make
RUN cp svm-scale /usr/local/bin/
RUN cp svm-predict /usr/local/bin/
RUN cp svm-train /usr/local/bin/
RUN rm -rf *

# Install mosquitto
RUN apt-get install -y mosquitto-clients mosquitto

# Install FIND
RUN go get github.com/schollz/find
WORKDIR "/usr/local/work/src/github.com/schollz/find"
RUN rm supervisord.conf
RUN go build -v
RUN echo "\ninclude_dir /usr/local/work/src/github.com/schollz/find/mosquitto" >> /etc/mosquitto/mosquitto.conf

# Setup supervisor
RUN apt-get update 
RUN apt-get install -y supervisor

# Add supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add Tini
ENV TINI_VERSION v0.13.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# Startup
CMD ["/usr/bin/supervisord"]

