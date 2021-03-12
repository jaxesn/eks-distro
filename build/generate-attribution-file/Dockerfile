# Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
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

FROM 316434458148.dkr.ecr.us-west-2.amazonaws.com/eks-distro/builder:199e941a6e1499870717e8b05178072e0b69b0fe as build

RUN go get github.com/google/go-licenses

ADD build /var/eks-distro/build
ADD projects/containernetworking/plugins/Makefile /var/eks-distro/projects/containernetworking/plugins/
ADD projects/containernetworking/plugins/build /var/eks-distro/projects/containernetworking/plugins/build


WORKDIR /var/eks-distro/containernetworking/plugins
RUN make binaries


FROM scratch as export
ARG RELEASE_BRANCH 
ARG KUBERNETES_ROOT
COPY --from=build /var/eks-distro/${KUBERNETES_ROOT}/${RELEASE_BRANCH}/checksums .
COPY --from=build /var/eks-distro/${KUBERNETES_ROOT}/${RELEASE_BRANCH}/KUBE_GIT_VERSION_FILE .
