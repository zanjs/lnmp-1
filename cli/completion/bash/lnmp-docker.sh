#!/bin/bash

complete -W "acme.sh \
        httpd-config \
        backup \
        build \
        build-config \
        build-up \
        cleanup \
        clusterkit \
        swarm-clusterkit \
        clusterkit-mysql-up \
        clusterkit-mysql-down \
        clusterkit-mysql-exec \
        clusterkit-mysql-deploy \
        clusterkit-mysql-remove \
        clusterkit-redis-up \
        clusterkit-redis-down \
        clusterkit-redis-exec \
        clusterkit-redis-create \
        clusterkit-redis-deploy \
        clusterkit-redis-remove \
        config \
        daemon-socket \
        development \
        development-pull \
        down \
        docs \
        full-up \
        help \
        k8s \
        k8s-down \
        new \
        push \
        restore \
        restart \
        registry \
        registry-down \
        ssl \
        ssl-self \
        swarm-build \
        swarm-config \
        swarm-deploy \
        swarm-down \
        swarm-ps \
        swarm-pull \
        swarm-push \
        swarm-update \
        tp \
        nginx-config \
        update \
        upgrade \
        init \
        commit \
        test \
        dockerfile-update \
        cn-mirror \
        compose" lnmp-docker.sh
