# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.14.2 AS build
WORKDIR /app

# CFG is the path to your configuration file
ARG CFG

# Set an env var that matches your github repo name, replace treeder/dockergo here with your repo name
ENV SRC_DIR=/src/tparty
ENV GO111MODULE=on

RUN mkdir -p ${SRC_DIR}/cmd ${SRC_DIR}/third_party ${SRC_DIR}/pkg ${SRC_DIR}/site /app/third_party /app/site
COPY go.* $SRC_DIR/
COPY cmd ${SRC_DIR}/cmd/
COPY pkg ${SRC_DIR}/pkg/

# Build the binary
RUN cd $SRC_DIR/cmd/server && go build -o main
RUN cp $SRC_DIR/cmd/server/main /app/

FROM gcr.io/distroless/base:nonroot

# Copy the binary from the build image
COPY --from=build /app/main /app/main

# Setup our deployment
COPY site /app/site/
COPY third_party /app/third_party/
COPY $CFG /app/config/config.yaml

# Run the server at a reasonable refresh rate
CMD ["/app/main", "--max_list_age=120s", "--max_refresh_age=20m", "--config=/app/config/config.yaml", "--site_dir=/app/site", "--3p_dir=/app/third_party"]
