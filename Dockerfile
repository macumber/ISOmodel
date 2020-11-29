FROM ubuntu:20.04

RUN apt-get update
RUN apt -y install software-properties-common dirmngr apt-transport-https lsb-release ca-certificates
#RUN apt-get install software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get install -y autoconf automake bison build-essential ca-certificates cmake cmake-curses-gui curl g++ gcc gnupg2 libc6-dev libffi-dev libgdbm-dev libncurses5-dev libsqlite3-dev libtool libyaml-dev make pkg-config sqlite3 zlib1g-dev libgmp-dev libreadline-dev libssl-dev ntp ntpdate python3.7 python3.7-dev python3-pip procps
RUN pip3 install conan && conan config set general.revisions_enabled=True && conan config set general.parallel_download=8

SHELL [ "/bin/bash", "-l", "-c" ]
RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s
RUN source /etc/profile.d/rvm.sh && rvm install 2.5.5 && rvm --default use 2.5.5
RUN usermod -a -G rvm root
RUN echo "source /etc/profile.d/rvm.sh" >> /root/.bashrc

CMD ["/bin/bash"]