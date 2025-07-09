FROM python:3.12-bullseye

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE 1
ENV PYTHONUNBUFFERED 1
ENV IN_MISAGO_DOCKER 1
ENV MISAGO_PLUGINS "/misago/plugins"

RUN <<EOF cat > /etc/apt/sources.list
deb http://mirrors.tencent.com/debian bullseye main contrib non-free
deb-src http://mirrors.tencent.com/debian bullseye main contrib non-free
deb http://mirrors.tencent.com/debian bullseye-updates main contrib non-free
deb-src http://mirrors.tencent.com/debian bullseye-updates main contrib non-free
deb http://mirrors.tencent.com/debian-security bullseye-security main contrib non-free
deb-src http://mirrors.tencent.com/debian-security bullseye-security main contrib non-free
deb http://mirrors.tencent.com/debian bullseye-backports main contrib non-free
deb-src http://mirrors.tencent.com/debian bullseye-backports main contrib non-free
deb http://mirrors.tencent.com/debian bullseye-proposed-updates main contrib non-free
deb-src http://mirrors.tencent.com/debian bullseye-proposed-updates main contrib non-free
EOF

RUN apt install curl ca-certificates \
 && install -d /usr/share/postgresql-common/pgdg \
 && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
 && . /etc/os-release \
 && sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt \$VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"

# Install dependencies in one single command/layer
RUN apt update && \
    apt install -y --allow-unauthenticated \
      vim \
      libffi-dev \
      libssl-dev \
      libjpeg-dev \
      libopenjp2-7-dev \
      locales \
      cron \
      postgresql-client-15 \
      gettext && \
    apt clean

# Make current directory available as "Misago" within docker
ADD . /misago
WORKDIR /misago

# Install requirements files
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Bootstrap plugins
RUN ./.run bootstrap_plugins

# Expose port 3031 from Docker
EXPOSE 3031

# Call entrypoint script to setup 
CMD ["uwsgi", "--ini", "uwsgi.ini"]