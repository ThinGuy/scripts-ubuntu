export ROW='\e[1;48;5;202m'
export BO='\e[38;5;202m'
export RO='\e[38;5;208m'
export BW='\e[1;37m'
export RT='\e[0m'

declare -a JUJU_HARVEST_MODES=(all destroyed none unknown)

help_JUJU_HARVEST_MODES()
{
printf "\n${ROW} Juju Harvesting Modes ${RT}\n${BW}"
col <<EOF

    You can control how Juju harvests machines by using the
    provisioner-harvest-mode setting. Harvesting is a process
    wherein Juju attempts to reclaim unused machines.

    Harvest mode is set in environments.yaml by using the 
    key:value pair of provisioner-harvest-mode: <option>

    Example:

        provisioner-harvest-mode: none

    Options are:

        all:          Harvest both dead and unknown machines.

        destroyed:    Only harvest machines that Juju knows about and are dead.

        none:         Don't harvest any machines.

        unknown:      Only harvest machines that Juju doesn't know about.

EOF
printf "\n\t${RT}${RO}See https://juju.ubuntu.com/docs for more information${RT}\n\n"
}

declare -a JUJU_ENV_TYPES=(amazon azure cloudsigma gce hpcloud joyent local maas manual openstack vmware)
[[ $JUJU_ENV_TYPE = "amazon" ]] && JUJU_ENV_TYPE_HELP='https://juju.ubuntu.com/docs/config-aws.html'
[[ $JUJU_ENV_TYPE = "azure" ]] && JUJU_ENV_TYPE_HELP='https://juju.ubuntu.com/docs/config-azure.html'
[[ $JUJU_ENV_TYPE = "cloudsigma" ]] && JUJU_ENV_TYPE_HELP='https://juju.ubuntu.com/docs/config-cloudsigma.html'
[[ $JUJU_ENV_TYPE = "gce" ]] && JUJU_ENV_TYPE_HELP='
[[ $JUJU_ENV_TYPE = "hpcloud" ]] && JUJU_ENV_TYPE_HELP='https://juju.ubuntu.com/docs/config-hpcloud.html'
[[ $JUJU_ENV_TYPE = "joyent" ]] && JUJU_ENV_TYPE_HELP='
[[ $JUJU_ENV_TYPE = "local" ]] && JUJU_ENV_TYPE_HELP='https://juju.ubuntu.com/docs/config-local.html'
[[ $JUJU_ENV_TYPE = "maas" ]] && JUJU_ENV_TYPE_HELP='https://juju.ubuntu.com/docs/config-maas.html'
[[ $JUJU_ENV_TYPE = "manual" ]] && JUJU_ENV_TYPE_HELP='
[[ $JUJU_ENV_TYPE = "openstack" ]] && JUJU_ENV_TYPE_HELP='https://juju.ubuntu.com/docs/config-openstack.html'
[[ $JUJU_ENV_TYPE = "vmware" ]] && JUJU_ENV_TYPE_HELP='






# Whether or not to refresh the list of available updates for an
# OS. The default option of true is recommended for use in
# production systems, but disabling this can speed up local
# deployments for development or testing.
#
# enable-os-refresh-update: true

# Whether or not to perform OS upgrades when machines are
# provisioned. The default option of true is recommended for use
# in production systems, but disabling this can speed up local
# deployments for development or testing.
#
# enable-os-upgrade: true

# You can control how Juju harvests machines by using the
# provisioner-harvest-mode setting. Harvesting is a process wherein
# Juju attempts to reclaim unused machines.
#
# Options are:
#
# Don't harvest any machines.
# provisioner-harvest-mode: none
#
# Only harvest machines that Juju knows about and are dead.
# provisioner-harvest-mode: destroyed
#
# Only harvest machines that Juju doesn't know about.
# provisioner-harvest-mode: unknown
#
# Harvest both dead and unknown machines.
# provisioner-harvest-mode: all