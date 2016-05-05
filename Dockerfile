# docker build -t ophidia_all .

FROM centos:centos6
MAINTAINER Mario David <mariojmdavid@gmail.com>
LABEL version="1.0.0"
LABEL description="Container image to run the Ophidia framework. (http://ophidia.cmcc.it)"

RUN yum -y install epel-release && \
    yum -y install http://repo.mysql.com/mysql-community-release-el6-7.noarch.rpm
    
RUN yum -y groupinstall 'development tools' && \
    yum -y install \
    curl \
    flex-devel \
    git \
    guile-devel \
    graphviz\* \
    gsl-devel \
    gsl \
    gtk2\* \
    httpd \
    jansson\* \
    libcurl-devel \
    libssh2\* \
    libtool-ltdl\* \
    libxml2\* \
    mpich\* \
    mysql-community-server \
    mysql-community-devel \
    munge\* \
	openssh-server \
    openssl-devel \
    php \
    policycoreutils-python \
    readline\* \
    sudo \
    wget

ENV CC /usr/lib64/mpich/bin/mpicc
ENV CPPFLAGS "-I/usr/local/ophidia/extra/include"
ENV LDFLAGS "-L/usr/local/ophidia/extra/lib"
ENV LIB -ldl

RUN mkdir -p /usr/local/ophidia/extra && \
    mkdir -p /var/www/html/ophidia && \
    mkdir -p /usr/local/ophidia/src && \
    mkdir -p /var/run/munge && \
    dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key && \
    useradd -r ophidia -d /usr/local/ophidia && \
    chown -R ophidia:ophidia /usr/local/ophidia && \
    chown -R ophidia:ophidia /var/www/html/ophidia && \
    chown -R munge:munge /var/run/munge && \
    chown -R munge:munge /etc/munge && \
    chmod 0711 /var/log/munge && \
    chmod 0755 /var/run/munge && \
    chmod 0400 /etc/munge/munge.key && \
    cd /usr/local && \
    wget http://ftp.gnu.org/gnu/libmatheval/libmatheval-1.1.11.tar.gz && \
    wget http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.16.tar.gz && \
    wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.0.tar.gz && \
    wget http://www.lip.pt/~david/gsoap_2.8.27.zip && \
    tar zxvf libmatheval-1.1.11.tar.gz && \
    tar zxvf hdf5-1.8.16.tar.gz && \
    tar zxvf netcdf-4.4.0.tar.gz && \
    unzip gsoap_2.8.27.zip && \
	git clone git://github.com/SchedMD/slurm.git && \
    cd /usr/local/ophidia/src && \
    git clone https://github.com/OphidiaBigData/ophidia-primitives && \
    git clone https://github.com/OphidiaBigData/ophidia-analytics-framework && \
    git clone https://github.com/OphidiaBigData/ophidia-server && \
    git clone https://github.com/OphidiaBigData/ophidia-terminal

RUN cd /usr/local/slurm/ && \
	./configure --prefix=/usr/local/ophidia/extra/ --sysconfdir=/usr/local/ophidia/extra/etc/ && \
	make && \
	make install && \
	mkdir /usr/local/ophidia/extra/etc && \
    cd /usr/local/libmatheval-1.1.11 && \
    ./configure --prefix=/usr/local/ophidia/extra  && \
    make && \
    make install && \
    cd /usr/local/hdf5-1.8.16 && \
    ./configure \
        --prefix=/usr/local/ophidia/extra \
        --enable-parallel && \
    make && \
    make install && \
    cd /usr/local/netcdf-4.4.0 && \
    ./configure \
        --prefix=/usr/local/ophidia/extra \
        --enable-parallel-tests && \
    make && \
    make install && \
    cd /usr/local/gsoap-2.8 && \
    ./configure \
        --prefix=/usr/local/ophidia/extra && \
    make && \
    make install

RUN cd /usr/local/ophidia/src/ophidia-primitives && \
	git checkout devel && \
    ./bootstrap && \
    ./configure \
        --prefix=/usr/local/ophidia/oph-cluster/oph-primitives \
        --with-matheval-path=/usr/local/ophidia/extra/ && \
    make && \
    make install && \
    cd /usr/local/ophidia/src/ophidia-analytics-framework && \
	git checkout devel && \
    ./bootstrap && \
    ./configure \
        --prefix=/usr/local/ophidia/oph-cluster/oph-analytics-framework \
        --enable-parallel-netcdf \
        --with-netcdf-path=/usr/local/ophidia/extra \
        --with-web-server-path=/var/www/html/ophidia \
        --with-web-server-url=http://127.0.0.1/ophidia && \
    make && \
    make install && \
    cd /usr/local/ophidia/src/ophidia-server && \
	git checkout devel && \
    ./bootstrap && \
    ./configure \
        --prefix=/usr/local/ophidia/oph-server \
        --with-framework-path=/usr/local/ophidia/oph-cluster/oph-analytics-framework \
        --with-soapcpp2-path=/usr/local/ophidia/extra \
        --enable-webaccess \
        --with-web-server-path=/var/www/html/ophidia \
        --with-web-server-url=http://127.0.0.1/ophidia && \
    make && \
    make install && \
	cp -r authz/ /usr/local/ophidia/oph-server/ && \
	mkdir  /usr/local/ophidia/oph-server/authz/sessions && \
    cd /usr/local/ophidia/src/ophidia-terminal && \
	git checkout devel && \
    ./bootstrap && \
    ./configure \
        --prefix=/usr/local/ophidia/oph-terminal && \
    make && \
    make install    

EXPOSE 22 80 443 11732
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD [ "/bin/bash" ]

