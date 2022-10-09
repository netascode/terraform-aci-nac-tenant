## 0.2.4 (unreleased)

- Fix BGP peer address family attribute order for L3out node profiles

## 0.2.3

- Add option to specific QoS class for external EPGs
- Add option to specific target DSCP value for external EPGs
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
- Make `community` and optional attribute of `set_rule`

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
