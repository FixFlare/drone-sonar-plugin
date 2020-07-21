FROM golang:1.13.11-alpine3.10 as build
RUN mkdir -p /go/src/github.com/aosapps/drone-sonar-plugin
WORKDIR /go/src/github.com/aosapps/drone-sonar-plugin 
COPY *.go ./
COPY vendor ./vendor/
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o drone-sonar

FROM openjdk:8-jre-alpine

ARG SONAR_VERSION=4.2.0.1873
ARG SONAR_SCANNER_CLI=sonar-scanner-cli-${SONAR_VERSION}
ARG SONAR_SCANNER=sonar-scanner-${SONAR_VERSION}

RUN apk add --no-cache --update \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    curl \
    nodejs
RUN apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust
    
RUN curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.0.2/powershell-7.0.2-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz \
&& mkdir -p /opt/microsoft/powershell/7 \
&& tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
&& chmod +x /opt/microsoft/powershell/7/pwsh \
&& ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh \
&& ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/powershell.exe

RUN pwsh -Command Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted \
&& pwsh -Command Install-Module -Name PSScriptAnalyzer

COPY --from=build /go/src/github.com/aosapps/drone-sonar-plugin/drone-sonar /bin/
WORKDIR /bin

RUN curl https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/${SONAR_SCANNER_CLI}.zip -so /bin/${SONAR_SCANNER_CLI}.zip
RUN unzip ${SONAR_SCANNER_CLI}.zip \
    && rm ${SONAR_SCANNER_CLI}.zip \
    && apk del curl

ENV PATH $PATH:/bin/${SONAR_SCANNER}/bin

ENTRYPOINT /bin/drone-sonar
