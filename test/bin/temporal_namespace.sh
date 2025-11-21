#!/bin/bash

TIMEOUT=10
NAMESPACE="temporal_sdk_tests"

create_namespace() {
	temporal operator namespace create -n "$NAMESPACE" >/dev/null 2>&1
	wait_for_namespace_registered
}

delete_namespace() {
	temporal operator namespace delete --yes -n "$NAMESPACE" >/dev/null 2>&1
	wait_for_namespace_deleted
}

wait_for_namespace_registered() {
	SECONDS=0
	until temporal operator namespace describe -n temporal_sdk_tests | grep Registered >/dev/null 2>&1; do

		if ((SECONDS > TIMEOUT)); then
			echo "===> Wait for namespace <$NAMESPACE> registration timeout."
			exit 1
		fi

		echo "===> Waiting for namespace <$NAMESPACE> registration..."
		sleep 1
	done
	sleep 1
}

wait_for_namespace_deleted() {
	SECONDS=0
	until ! temporal operator namespace describe -n temporal_sdk_tests >/dev/null 2>&1; do

		if ((SECONDS > TIMEOUT)); then
			echo "===> Wait for namespace <$NAMESPACE> deletion timeout."
			exit 1
		fi

		echo "===> Waiting for namespace <$NAMESPACE> deletion..."
		sleep 1
	done
	sleep 1
}

if ! [ -x "$(command -v temporal)" ]; then
	exit 0
fi

echo "===> Recreating Temporal namespace <$NAMESPACE>..."

if temporal operator cluster health >/dev/null 2>&1; then
	if temporal operator namespace describe -n "$NAMESPACE" >/dev/null 2>&1; then
		delete_namespace
		create_namespace
	else
		create_namespace
	fi
else
	echo Error dialing Temporal server at 127.0.0.1:7233.
	exit 1
fi
