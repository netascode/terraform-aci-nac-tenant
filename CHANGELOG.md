## 0.4.3 (unreleased)

- Make the L3out node profile BGP peer `password` variable sensitive

## 0.4.2

- Fix conditional creation of `fvUplinkOrderCont` object for EPGs

## 0.4.1

- Fix issue with L3out `next_hop_self` attribute

## 0.4.0

- Fix VRF leaked internal prefix destination public default value
- Add BGP peer prefix policy
- Add BGP best path policy
- Add IGMP interface policy
- Add IGMP snooping policy
- Add `virtual_mac` and `ep_move_detection` attributes to bridge domain
- Add `pim` attributes to VRF
- Add PIM policy
- Add VRF BGP IPv4/IPv6 import/export route targets
- Add service EPG policy
- Add trust control policy
- Add redirect backup policy
- Add service EPG policy reference to device selection policy
- Add custom QoS policy to device selection policy
- Add multicast route map
- Add static endpoints to EPGs
- Add tags to EPGs
- Add trust control policy to EPGs
- Add L4L7 virtual IPs to EPGs
- Add L4L7 address pools to EPGs
- Add tenant SPAN destination group
- Add tenant SPAN source group
- Include default values in module
- BREAKING CHANGE: `depends_on` can no longer be used to express explicit dependencies between NaC modules. The variable `dependencies` and the output `critical_resources_done` can be used instead, to ensure a certain order of operations.
- Add `elag`, `active_uplinks_order` and `standby_uplinks` attributes to VMware VMM domain EPG associations

## 0.3.3

- Add QoS attributes to contract
- Add `managed` flag to tenant (default value `true`) to indicate if a tenant should be created/modified/deleted or is assumed to exist already and just acts a container for other objects
- Add `managed` flag to application profile
- Remove option to specify tenant for EPG selectors under an ESG
- Normalize filter `protocol` and `port` values
- Allow escaping character in ESG tag selectors
- Add `qos_class` attribute to EPG
- Allow OSPF area IDs in dotted decimal format

## 0.3.2

- Add support for L4-L7 device logical interfaces without encap
- Add support for L4-L7 device logical interfaces without paths
- Add `vmware_vmm_domain` attribute to L4-L7 device
- Add `regex_community_terms` attribute to match rules
- Add `community_terms` attribute to match rules
- Fix tag selector variable validation of endpoint security group
- Add support for imported consumers (contract interface) to ESGs
- Add support for leaked internal and external prefixes to VRF
- Add support for intra-EPG contracts
- Add support for intra-ESG contracts
- Fix [issue](https://github.com/netascode/terraform-aci-nac-tenant/issues/13) related to ESG deployment with EPG selectors

## 0.3.1

- Harmonize module flags
- Fix service graph association in contract subjects
- Fix L3out interface type derivation

## 0.3.0

- Fix BGP peer address family attribute order for L3out node profiles
- Add additional attributes to set rules
- Add additional attributes to redirect policies
- Add `preferred_group` attribute to VRF
- Add BGP address family context policies to VRF
- Add IP SLA policy module
- Add BGP address family context policy module
- Add redirect health group module
- Add route control route map module
- Add QoS policy module
- Add custom QoS policy attribute to EPG
- Pin module dependencies

## 0.2.3

- Add option to specify QoS class for external EPGs
- Add option to specify target DSCP value for external EPGs
- Add aggregate flags to subnet of external EPGs
- Add option to enable IPv4 multicast for L3out
- Add option to specify target DSCP for L3out
- Add option to reference interleak, dampening and redistribution route maps for L3out
- Add option to configure default route leak policy for L3out
- Add support for node loopbacks in L3out node profiles
- Add support for static route BFD in L3out node profiles
- Add support for loopback BGP peerings in L3out node profiles
- Add support for PIM policy in L3out interface profiles
- Add support for IGMP interface policy in L3out interface profiles
- Add support for QoS class in L3out interface profiles
- Add support for custom QoS policy in L3out interface profiles
- Add support for floating SVI in L3out interface profiles
- Add multiple options to BGP peers in L3out interface profiles
- Fix default tenant for service graph templates and device selection policies
- Make `community` an optional attribute of `set_rule`

## 0.2.2

- BREAKING CHANGE: Change EPG preferred group attribute to boolean value
- BREAKING CHANGE: Change External EPG preferred group attribute to boolean value
- BREAKING CHANGE: Change EPG intra-EPG isolation attribute to boolean value

## 0.2.1

- Add support for endpoint security groups

## 0.2.0

- Use Terraform 1.3 compatible modules

## 0.1.4

- Update readme and add link to Nexus-as-Code project documentation

## 0.1.3

- Fix BFD interface policy name suffix reference of L3out interface profile
- Improve node and pod ID lookups

## 0.1.2

- Fix setting BGP flag for L3outs

## 0.1.1

- Fix handling of provided node IDs for EPGs, L3outs and L4L7 devices

## 0.1.0

- Initial release
