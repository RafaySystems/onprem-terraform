#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${CLUSTER_NAME
}

${USER_CUSTOM_COMMANDS
}
