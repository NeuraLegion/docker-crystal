FROM ubuntu:20.04 AS gc_builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends wget \
  ca-certificates autoconf autotools-dev automake patch libtool git ssh make g++ apt-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/gc
WORKDIR /opt/gc

RUN git clone https://github.com/ivmai/bdwgc.git
WORKDIR /opt/gc/bdwgc
RUN git checkout 57b97be07c514fcc4b608b13768fd2bf637a5899
COPY unmap_debug.patch ./
RUN patch -p1 < unmap_debug.patch
RUN ./autogen.sh
RUN ./configure --enable-cplusplus --enable-static=yes --enable-shared=no
RUN sed -i -e 's/ -shared / -Wl,-O1,--as-needed\0/g' libtool
RUN make CFLAGS="-g3"
ENTRYPOINT [ "bash" ]

FROM ubuntu:20.04 AS crystal-base

ENV DEBIAN_FRONTEND=noninteractive

# Setup for multiparse ssh
RUN apt-get update && apt-get install -y --no-install-recommends \
  openssh-client git curl gnupg2 ca-certificates apt-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*


RUN apt-get update && apt-get install -y --no-install-recommends \
  make libyaml-dev libxml2-dev gcc pkg-config libpcre3-dev libgmp-dev libz-dev libevent-dev wget libssl-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install Crystal from it's source
RUN wget -O crystal.deb https://github.com/crystal-lang/crystal/releases/download/0.36.1/crystal_0.36.1-1_amd64.deb && \
  dpkg -i crystal.deb

RUN rm /usr/lib/crystal/lib/libgc.a
COPY --from=gc_builder /opt/gc/bdwgc/.libs/libgc.a /usr/lib/crystal/lib/libgc.a
