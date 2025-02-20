ARG BUILD_FROM
ARG PYTHON_VERSION=3.9
ARG LIBCEC6_VERSION=6.0.2

FROM $BUILD_FROM AS builder
ARG PYTHON_VERSION
ARG LIBCEC6_VERSION
ENV LANG C.UTF-8
RUN apk add --no-cache \
        eudev-libs \
        p8-platform \
        raspberrypi-dev \
        python3 \
        python3-dev \
        build-base \
        cmake \
        ninja \
        eudev-dev \
        swig \
        p8-platform-dev \
        git
RUN mkdir -p /usr/src
RUN git clone --depth 1 https://github.com/barneyman/libcec /usr/src/libcec
RUN mkdir /usr/src/libcec/build
WORKDIR /usr/src/libcec/build
RUN cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr \
    -DRPI_INCLUDE_DIR=/opt/vc/include \
    -DRPI_LIB_DIR=/opt/vc/lib \
    -DPYTHON_LIBRARY="/usr/lib/libpython3.9.so" \
    -DPYTHON_INCLUDE_DIR="/usr/include/python3.9" \
    -GNinja ..
RUN ninja install

FROM $BUILD_FROM
ARG PYTHON_VERSION
ARG LIBCEC6_VERSION
RUN apk add --no-cache raspberrypi python3 p8-platform py3-pip eudev-libs
RUN echo /lib:/usr/local/lib:/usr/lib:/opt/vc/lib > /etc/ld-musl-armhf.path
RUN echo cec > "~/.local/lib/python3.9/site-packages/cec.pth"
COPY --from=builder ~/.local/lib/python3.9/site-packages/cec.py ~/.local/lib/python3.9/site-packages/
COPY --from=builder ~/.local/lib/python3.9/site-packages/_cec.so ~/.local/lib/python3.9/site-packages/
COPY --from=builder /usr/lib/libcec.so.$LIBCEC6_VERSION /usr/lib/
RUN ln -s libcec.so.$LIBCEC6_VERSION /usr/lib/libcec.so.6
RUN ln -s libcec.so.6
RUN pip install pycec -U
CMD [ "python3", "-m", "pycec", "--quiet" ]
