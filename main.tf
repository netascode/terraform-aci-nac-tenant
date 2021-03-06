locals {
  defaults           = lookup(var.model, "defaults", {})
  modules            = lookup(var.model, "modules", {})
  apic               = lookup(var.model, "apic", {})
  access_policies    = lookup(local.apic, "access_policies", {})
  node_policies      = lookup(local.apic, "node_policies", {})
  interface_policies = lookup(local.apic, "interface_policies", {})
  tenant             = [for tenant in lookup(local.apic, "tenants", {}) : tenant if tenant.name == var.tenant_name][0]
  leaf_interface_policy_group_mapping = [
    for pg in lookup(local.access_policies, "leaf_interface_policy_groups", []) : {
      name = pg.name
      type = pg.type
      node_ids = [
        for node in lookup(local.interface_policies, "nodes", []) :
        node.id if length([for int in node.interfaces : lookup(int, "policy_group", null) if lookup(int, "policy_group", null) == pg.name]) > 0
      ]
    }
  ]

  # first iteration to resolve node_id and determine IPG type for static ports
  endpoint_groups = flatten([for ap in lookup(local.tenant, "application_profiles", []) : [
    for epg in lookup(ap, "endpoint_groups", []) : {
      key = "${ap.name}/${epg.name}"
      value = {
        application_profile         = "${ap.name}${local.defaults.apic.tenants.application_profiles.name_suffix}"
        name                        = "${epg.name}${local.defaults.apic.tenants.application_profiles.endpoint_groups.name_suffix}"
        alias                       = lookup(epg, "alias", "")
        description                 = lookup(epg, "description", "")
        flood_in_encap              = lookup(epg, "flood_in_encap", local.defaults.apic.tenants.application_profiles.endpoint_groups.flood_in_encap)
        intra_epg_isolation         = lookup(epg, "intra_epg_isolation", local.defaults.apic.tenants.application_profiles.endpoint_groups.intra_epg_isolation) == "enforced" ? true : false
        preferred_group             = lookup(epg, "preferred_group", local.defaults.apic.tenants.application_profiles.endpoint_groups.preferred_group) == "include" ? true : false
        bridge_domain               = lookup(epg, "bridge_domain", null) != null ? "${epg.bridge_domain}${local.defaults.apic.tenants.bridge_domains.name_suffix}" : ""
        contract_consumers          = lookup(lookup(epg, "contracts", {}), "consumers", null) != null ? [for contract in epg.contracts.consumers : "${contract}${local.defaults.apic.tenants.contracts.name_suffix}"] : []
        contract_providers          = lookup(lookup(epg, "contracts", {}), "providers", null) != null ? [for contract in epg.contracts.providers : "${contract}${local.defaults.apic.tenants.contracts.name_suffix}"] : []
        contract_imported_consumers = lookup(lookup(epg, "contracts", {}), "imported_consumers", null) != null ? [for contract in epg.contracts.imported_consumers : "${contract}${local.defaults.apic.tenants.imported_contracts.name_suffix}"] : []
        physical_domains            = lookup(epg, "physical_domains", null) != null ? [for domain in epg.physical_domains : "${domain}${local.defaults.apic.access_policies.physical_domains.name_suffix}"] : []
        static_ports = [for sp in lookup(epg, "static_ports", []) : {
          node_id = lookup(sp, "node_id", lookup(sp, "channel", null) != null ? try([for pg in local.leaf_interface_policy_group_mapping : lookup(pg, "node_ids", []) if pg.name == lookup(sp, "channel", null)][0][0], null) : null)
          # set node2_id to "vpc" if channel IPG is vPC, otherwise "null"
          node2_id             = lookup(sp, "node2_id", lookup(sp, "channel", null) != null ? try([for pg in local.leaf_interface_policy_group_mapping : pg.type if pg.name == lookup(sp, "channel", null) && pg.type == "vpc"][0], null) : null)
          pod_id               = lookup(sp, "pod_id", null)
          channel              = lookup(sp, "channel", null) != null ? "${sp.channel}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}" : null
          port                 = lookup(sp, "port", null)
          sub_port             = lookup(sp, "sub_port", null)
          module               = lookup(sp, "module", null)
          vlan                 = lookup(sp, "vlan", null)
          deployment_immediacy = lookup(sp, "deployment_immediacy", local.defaults.apic.tenants.application_profiles.endpoint_groups.static_ports.deployment_immediacy)
          mode                 = lookup(sp, "mode", local.defaults.apic.tenants.application_profiles.endpoint_groups.static_ports.mode)
        }]
        vmware_vmm_domains = [for vmm in lookup(epg, "vmware_vmm_domains", []) : {
          name                 = "${vmm.name}${local.defaults.apic.fabric_policies.vmware_vmm_domains.name_suffix}"
          u_segmentation       = lookup(vmm, "u_segmentation", local.defaults.apic.tenants.application_profiles.endpoint_groups.vmware_vmm_domains.u_segmentation)
          delimiter            = lookup(vmm, "delimiter", local.defaults.apic.tenants.application_profiles.endpoint_groups.vmware_vmm_domains.delimiter)
          vlan                 = lookup(vmm, "vlan", null)
          primary_vlan         = lookup(vmm, "primary_vlan", null)
          secondary_vlan       = lookup(vmm, "secondary_vlan", null)
          netflow              = lookup(vmm, "netflow", local.defaults.apic.tenants.application_profiles.endpoint_groups.vmware_vmm_domains.netflow)
          deployment_immediacy = lookup(vmm, "deployment_immediacy", local.defaults.apic.tenants.application_profiles.endpoint_groups.vmware_vmm_domains.deployment_immediacy)
          resolution_immediacy = lookup(vmm, "resolution_immediacy", local.defaults.apic.tenants.application_profiles.endpoint_groups.vmware_vmm_domains.resolution_immediacy)
          allow_promiscuous    = lookup(vmm, "allow_promiscuous", local.defaults.apic.tenants.application_profiles.endpoint_groups.vmware_vmm_domains.allow_promiscuous) == "accept" ? true : false
          forged_transmits     = lookup(vmm, "forged_transmits", local.defaults.apic.tenants.application_profiles.endpoint_groups.vmware_vmm_domains.forged_transmits) == "accept" ? true : false
          mac_changes          = lookup(vmm, "mac_changes", local.defaults.apic.tenants.application_profiles.endpoint_groups.vmware_vmm_domains.mac_changes) == "accept" ? true : false
        }]
        subnets = [for subnet in lookup(epg, "subnets", []) : {
          description        = lookup(subnet, "description", "")
          ip                 = subnet.ip
          public             = lookup(subnet, "public", local.defaults.apic.tenants.application_profiles.endpoint_groups.subnets.public)
          shared             = lookup(subnet, "shared", local.defaults.apic.tenants.application_profiles.endpoint_groups.subnets.shared)
          igmp_querier       = lookup(subnet, "igmp_querier", local.defaults.apic.tenants.application_profiles.endpoint_groups.subnets.igmp_querier)
          nd_ra_prefix       = lookup(subnet, "nd_ra_prefix", local.defaults.apic.tenants.application_profiles.endpoint_groups.subnets.nd_ra_prefix)
          no_default_gateway = lookup(subnet, "no_default_gateway", local.defaults.apic.tenants.application_profiles.endpoint_groups.subnets.no_default_gateway)
        }]
      }
    }]
  ])

  l3outs = [for l3out in lookup(local.tenant, "l3outs", []) : {
    name        = "${l3out.name}${local.defaults.apic.tenants.l3outs.name_suffix}"
    alias       = lookup(l3out, "alias", "")
    description = lookup(l3out, "description", "")
    domain      = "${l3out.domain}${local.defaults.apic.access_policies.routed_domains.name_suffix}"
    vrf         = "${l3out.vrf}${local.defaults.apic.tenants.vrfs.name_suffix}"
    bgp = anytrue([
      anytrue(
        flatten([for np in lookup(l3out, "node_profiles", []) : [
          for ip in lookup(np, "interface_profiles", []) : [
            for int in lookup(ip, "interfaces", []) : lookup(int, "bgp_peers", null) != null
          ]
        ]])
      ),
      anytrue(
        flatten([for node in lookup(l3out, "nodes", []) : [
          for int in lookup(node, "interfaces", []) : lookup(int, "bgp_peers", null) != null
        ]])
      ),
    ])
    ospf                         = lookup(l3out, "ospf", null) != null ? true : false
    ospf_area                    = lookup(lookup(l3out, "ospf", {}), "area", "backbone")
    ospf_area_cost               = lookup(lookup(l3out, "ospf", {}), "area_cost", local.defaults.apic.tenants.l3outs.ospf.area_cost)
    ospf_area_type               = lookup(lookup(l3out, "ospf", {}), "area_type", local.defaults.apic.tenants.l3outs.ospf.area_type)
    import_route_map_description = lookup(lookup(l3out, "import_route_map", {}), "description", "")
    import_route_map_type        = lookup(lookup(l3out, "import_route_map", {}), "type", local.defaults.apic.tenants.l3outs.import_route_map.type)
    import_route_map_contexts = [for context in lookup(lookup(l3out, "import_route_map", {}), "contexts", []) : {
      name        = "${context.name}${local.defaults.apic.tenants.l3outs.import_route_map.contexts.name_suffix}"
      description = lookup(context, "description", "")
      action      = lookup(context, "action", local.defaults.apic.tenants.l3outs.import_route_map.contexts.action)
      order       = lookup(context, "order", local.defaults.apic.tenants.l3outs.import_route_map.contexts.order)
      set_rule    = lookup(context, "set_rule", null) != null ? "${context.set_rule}${local.defaults.apic.tenants.policies.set_rules.name_suffix}" : ""
      match_rule  = lookup(context, "match_rule", null) != null ? "${context.match_rule}${local.defaults.apic.tenants.policies.match_rules.name_suffix}" : ""
    }]
    export_route_map_description = lookup(lookup(l3out, "export_route_map", {}), "description", "")
    export_route_map_type        = lookup(lookup(l3out, "export_route_map", {}), "type", local.defaults.apic.tenants.l3outs.export_route_map.type)
    export_route_map_contexts = [for context in lookup(lookup(l3out, "export_route_map", {}), "contexts", []) : {
      name        = "${context.name}${local.defaults.apic.tenants.l3outs.export_route_map.contexts.name_suffix}"
      description = lookup(context, "description", "")
      action      = lookup(context, "action", local.defaults.apic.tenants.l3outs.export_route_map.contexts.action)
      order       = lookup(context, "order", local.defaults.apic.tenants.l3outs.export_route_map.contexts.order)
      set_rule    = lookup(context, "set_rule", null) != null ? "${context.set_rule}${local.defaults.apic.tenants.policies.set_rules.name_suffix}" : ""
      match_rule  = lookup(context, "match_rule", null) != null ? "${context.match_rule}${local.defaults.apic.tenants.policies.match_rules.name_suffix}" : ""
    }]
  }]

  node_profiles_manual = flatten([for l3out in lookup(local.tenant, "l3outs", []) : [
    for np in lookup(l3out, "node_profiles", []) : {
      key = "${l3out.name}/${np.name}"
      value = {
        l3out = l3out.name
        name  = "${np.name}${local.defaults.apic.tenants.l3outs.node_profiles.name_suffix}"
        nodes = [for node in lookup(np, "nodes", []) : {
          node_id               = node.node_id
          pod_id                = lookup(node, "pod_id", try([for node_ in lookup(local.node_policies, "nodes", []) : node_.pod if node_.id == node.node_id][0], local.defaults.apic.tenants.l3outs.node_profiles.nodes.pod))
          router_id             = node.router_id
          router_id_as_loopback = lookup(node, "router_id_as_loopback", local.defaults.apic.tenants.l3outs.node_profiles.nodes.router_id_as_loopback)
          static_routes = [for sr in lookup(node, "static_routes", []) : {
            description = lookup(sr, "description", "")
            prefix      = sr.prefix
            preference  = lookup(sr, "preference", local.defaults.apic.tenants.l3outs.node_profiles.nodes.static_routes.preference)
            next_hops = [for nh in lookup(sr, "next_hops", []) : {
              ip         = nh.ip
              preference = lookup(nh, "preference", local.defaults.apic.tenants.l3outs.node_profiles.nodes.static_routes.next_hops.preference)
              type       = lookup(nh, "type", local.defaults.apic.tenants.l3outs.node_profiles.nodes.static_routes.next_hops.type)
            }]
          }]
        }]
      }
    }]
  ])

  node_profiles_auto = [for l3out in lookup(local.tenant, "l3outs", []) : {
    l3out = l3out.name
    name  = l3out.name
    nodes = [for node in lookup(l3out, "nodes", []) : {
      node_id               = node.node_id
      pod_id                = lookup(node, "pod_id", try([for node_ in lookup(local.node_policies, "nodes", []) : node_.pod if node_.id == node.node_id][0], local.defaults.apic.tenants.l3outs.nodes.pod))
      router_id             = node.router_id
      router_id_as_loopback = lookup(node, "router_id_as_loopback", local.defaults.apic.tenants.l3outs.nodes.router_id_as_loopback)
      static_routes = [for sr in lookup(node, "static_routes", []) : {
        description = lookup(sr, "description", "")
        prefix      = sr.prefix
        preference  = lookup(sr, "preference", local.defaults.apic.tenants.l3outs.nodes.static_routes.preference)
        next_hops = [for nh in lookup(sr, "next_hops", []) : {
          ip         = nh.ip
          preference = lookup(nh, "preference", local.defaults.apic.tenants.l3outs.nodes.static_routes.next_hops.preference)
          type       = lookup(nh, "type", local.defaults.apic.tenants.l3outs.nodes.static_routes.next_hops.type)
        }]
      }]
    }]
  } if length(lookup(l3out, "nodes", [])) != 0]

  interface_profiles_manual = flatten([for l3out in lookup(local.tenant, "l3outs", []) : [
    for np in lookup(l3out, "node_profiles", []) : [
      for ip in lookup(np, "interface_profiles", []) : {
        key = "${l3out.name}/${np.name}/${ip.name}"
        value = {
          l3out                       = l3out.name
          node_profile                = np.name
          name                        = "${ip.name}${local.defaults.apic.tenants.l3outs.node_profiles.interface_profiles.name_suffix}"
          bfd_policy                  = lookup(ip, "bfd_policy", null) != null ? "${ip.bfd_policy}${local.defaults.apic.tenants.policies.bfd_interface_policies.name_suffix}" : ""
          ospf_interface_profile_name = lookup(lookup(ip, "ospf", {}), "ospf_interface_profile_name", "")
          ospf_authentication_key     = lookup(lookup(ip, "ospf", {}), "auth_key", "")
          ospf_authentication_key_id  = lookup(lookup(ip, "ospf", {}), "auth_key_id", "1")
          ospf_authentication_type    = lookup(lookup(ip, "ospf", {}), "auth_type", "none")
          ospf_interface_policy       = lookup(lookup(ip, "ospf", {}), "policy", "")
          interfaces = lookup(ip, "interfaces", null) == null ? null : [for int in ip.interfaces : {
            ip          = lookup(int, "ip", "")
            svi         = lookup(int, "svi", local.defaults.apic.tenants.l3outs.node_profiles.interface_profiles.interfaces.svi)
            vlan        = lookup(int, "vlan", null)
            description = lookup(int, "description", "")
            type        = lookup(int, "port", null) != null ? "access" : ([for pg in local.leaf_interface_policy_group_mapping : pg.type if pg.name == lookup(int, "channel", null)][0])
            mac         = lookup(int, "mac", local.defaults.apic.tenants.l3outs.node_profiles.interface_profiles.interfaces.mac)
            mtu         = lookup(int, "mtu", local.defaults.apic.tenants.l3outs.node_profiles.interface_profiles.interfaces.mtu)
            node_id     = lookup(int, "node_id", lookup(int, "channel", null) != null ? try([for pg in local.leaf_interface_policy_group_mapping : lookup(pg, "node_ids", []) if pg.name == lookup(int, "channel", null)][0][0], null) : null)
            node2_id    = lookup(int, "node2_id", lookup(int, "channel", null) != null ? try([for pg in local.leaf_interface_policy_group_mapping : pg.type if pg.name == lookup(int, "channel", null) && pg.type == "vpc"][0], null) : null)
            pod_id      = lookup(int, "pod_id", null)
            module      = lookup(int, "module", local.defaults.apic.tenants.l3outs.node_profiles.interface_profiles.interfaces.module)
            port        = lookup(int, "port", null)
            channel     = lookup(int, "channel", null) != null ? "${int.channel}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}" : null
            ip_a        = lookup(int, "ip_a", null)
            ip_b        = lookup(int, "ip_b", null)
            ip_shared   = lookup(int, "ip_shared", null)
            bgp_peers = lookup(int, "bgp_peers", null) == null ? null : [for peer in lookup(int, "bgp_peers", []) : {
              ip          = peer.ip
              description = lookup(peer, "description", "")
              bfd         = lookup(peer, "bfd", local.defaults.apic.tenants.l3outs.node_profiles.interface_profiles.interfaces.bgp_peers.bfd)
              ttl         = lookup(peer, "ttl", local.defaults.apic.tenants.l3outs.node_profiles.interface_profiles.interfaces.bgp_peers.ttl)
              weight      = lookup(peer, "weight", local.defaults.apic.tenants.l3outs.node_profiles.interface_profiles.interfaces.bgp_peers.weight)
              password    = lookup(peer, "password", null)
              remote_as   = peer.remote_as
            }]
          }]
        }
      }
    ]
  ]])

  interface_profiles_auto = [for l3out in lookup(local.tenant, "l3outs", []) : {
    l3out                       = l3out.name
    node_profile                = l3out.name
    name                        = l3out.name
    bfd_policy                  = lookup(l3out, "bfd_policy", null) != null ? "${l3out.bfd_policy}${local.defaults.apic.tenants.policies.bfd_interface_policies.name_suffix}" : ""
    ospf_interface_profile_name = lookup(lookup(l3out, "ospf", {}), "ospf_interface_profile_name", l3out.name)
    ospf_authentication_key     = lookup(lookup(l3out, "ospf", {}), "auth_key", "")
    ospf_authentication_key_id  = lookup(lookup(l3out, "ospf", {}), "auth_key_id", "1")
    ospf_authentication_type    = lookup(lookup(l3out, "ospf", {}), "auth_type", "none")
    ospf_interface_policy       = lookup(lookup(l3out, "ospf", {}), "policy", "")
    interfaces = flatten([for node in lookup(l3out, "nodes", []) : [
      for int in lookup(node, "interfaces", []) : {
        ip          = lookup(int, "ip", "")
        svi         = lookup(int, "svi", local.defaults.apic.tenants.l3outs.nodes.interfaces.svi)
        vlan        = lookup(int, "vlan", null)
        description = lookup(int, "description", "")
        type        = lookup(int, "port", null) != null ? "access" : ([for pg in local.leaf_interface_policy_group_mapping : pg.type if pg.name == lookup(int, "channel", null)][0])
        mac         = lookup(int, "mac", local.defaults.apic.tenants.l3outs.nodes.interfaces.mac)
        mtu         = lookup(int, "mtu", local.defaults.apic.tenants.l3outs.nodes.interfaces.mtu)
        node_id     = lookup(node, "node_id", lookup(int, "channel", null) != null ? try([for pg in local.leaf_interface_policy_group_mapping : lookup(pg, "node_ids", []) if pg.name == lookup(int, "channel", null)][0][0], null) : null)
        node2_id    = lookup(int, "node2_id", lookup(int, "channel", null) != null ? try([for pg in local.leaf_interface_policy_group_mapping : pg.type if pg.name == lookup(int, "channel", null) && pg.type == "vpc"][0], null) : null)
        pod_id      = lookup(int, "pod_id", null)
        module      = lookup(int, "module", local.defaults.apic.tenants.l3outs.nodes.interfaces.module)
        port        = lookup(int, "port", null)
        channel     = lookup(int, "channel", null) != null ? "${int.channel}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}" : null
        ip_a        = lookup(int, "ip_a", null)
        ip_b        = lookup(int, "ip_b", null)
        ip_shared   = lookup(int, "ip_shared", null)
        bgp_peers = lookup(int, "bgp_peers", null) == null ? null : [for peer in lookup(int, "bgp_peers", []) : {
          ip          = peer.ip
          description = lookup(peer, "description", "")
          bfd         = lookup(peer, "bfd", local.defaults.apic.tenants.l3outs.nodes.interfaces.bgp_peers.bfd)
          ttl         = lookup(peer, "ttl", local.defaults.apic.tenants.l3outs.nodes.interfaces.bgp_peers.ttl)
          weight      = lookup(peer, "weight", local.defaults.apic.tenants.l3outs.nodes.interfaces.bgp_peers.weight)
          password    = lookup(peer, "password", null)
          remote_as   = peer.remote_as
        }]
      }
    ]])
  } if length(lookup(l3out, "nodes", [])) != 0]

  external_endpoint_groups = flatten([for l3out in lookup(local.tenant, "l3outs", []) : [
    for epg in lookup(l3out, "external_endpoint_groups", []) : {
      key = "${l3out.name}/${epg.name}"
      value = {
        l3out                       = "${l3out.name}${local.defaults.apic.tenants.l3outs.name_suffix}"
        name                        = "${epg.name}${local.defaults.apic.tenants.l3outs.external_endpoint_groups.name_suffix}"
        alias                       = lookup(epg, "alias", "")
        description                 = lookup(epg, "description", "")
        preferred_group             = lookup(epg, "preferred_group", local.defaults.apic.tenants.l3outs.external_endpoint_groups.preferred_group) == "include" ? true : false
        contract_consumers          = lookup(lookup(epg, "contracts", {}), "consumers", null) != null ? [for contract in epg.contracts.consumers : "${contract}${local.defaults.apic.tenants.contracts.name_suffix}"] : []
        contract_providers          = lookup(lookup(epg, "contracts", {}), "providers", null) != null ? [for contract in epg.contracts.providers : "${contract}${local.defaults.apic.tenants.contracts.name_suffix}"] : []
        contract_imported_consumers = lookup(lookup(epg, "contracts", {}), "imported_consumers", null) != null ? [for contract in epg.contracts.imported_consumers : "${contract}${local.defaults.apic.tenants.imported_contracts.name_suffix}"] : []
        subnets = [for subnet in lookup(epg, "subnets", []) : {
          name                    = lookup(subnet, "name", "")
          prefix                  = subnet.prefix
          import_route_control    = lookup(subnet, "import_route_control", local.defaults.apic.tenants.l3outs.external_endpoint_groups.subnets.import_route_control)
          export_route_control    = lookup(subnet, "export_route_control", local.defaults.apic.tenants.l3outs.external_endpoint_groups.subnets.export_route_control)
          shared_route_control    = lookup(subnet, "shared_route_control", local.defaults.apic.tenants.l3outs.external_endpoint_groups.subnets.shared_route_control)
          import_security         = lookup(subnet, "import_security", local.defaults.apic.tenants.l3outs.external_endpoint_groups.subnets.import_security)
          shared_security         = lookup(subnet, "shared_security", local.defaults.apic.tenants.l3outs.external_endpoint_groups.subnets.shared_security)
          bgp_route_summarization = lookup(subnet, "bgp_route_summarization", local.defaults.apic.tenants.l3outs.external_endpoint_groups.subnets.bgp_route_summarization)
        }]
      }
    }]
  ])

  l4l7_devices = [for device in lookup(lookup(local.tenant, "services", {}), "l4l7_devices", []) : {
    name             = "${device.name}${local.defaults.apic.tenants.services.l4l7_devices.name_suffix}"
    alias            = lookup(device, "alias", "")
    context_aware    = lookup(device, "context_aware", local.defaults.apic.tenants.services.l4l7_devices.context_aware)
    type             = lookup(device, "type", local.defaults.apic.tenants.services.l4l7_devices.type)
    function         = lookup(device, "function", local.defaults.apic.tenants.services.l4l7_devices.function)
    copy_device      = lookup(device, "copy_device", local.defaults.apic.tenants.services.l4l7_devices.copy_device)
    managed          = lookup(device, "managed", local.defaults.apic.tenants.services.l4l7_devices.managed)
    promiscuous_mode = lookup(device, "promiscuous_mode", local.defaults.apic.tenants.services.l4l7_devices.promiscuous_mode)
    service_type     = lookup(device, "service_type", local.defaults.apic.tenants.services.l4l7_devices.service_type)
    trunking         = lookup(device, "trunking", local.defaults.apic.tenants.services.l4l7_devices.trunking)
    physical_domain  = lookup(device, "physical_domain", "")
    concrete_devices = [for cdev in lookup(device, "concrete_devices", []) : {
      name         = "${cdev.name}${local.defaults.apic.tenants.services.l4l7_devices.concrete_devices.name_suffix}"
      alias        = lookup(cdev, "alias", null)
      description  = lookup(cdev, "description", null)
      vcenter_name = lookup(cdev, "vcenter_name", null)
      vm_name      = lookup(cdev, "vm_name", null)
      interfaces = [for int in lookup(cdev, "interfaces", []) : {
        name      = "${int.name}${local.defaults.apic.tenants.services.l4l7_devices.concrete_devices.interfaces.name_suffix}"
        alias     = lookup(int, "alias", null)
        vnic_name = lookup(int, "vnic_name", null)
        node_id   = lookup(int, "node_id", lookup(int, "channel", null) != null ? try([for pg in local.leaf_interface_policy_group_mapping : lookup(pg, "node_ids", []) if pg.name == lookup(int, "channel", null)][0][0], null) : null)
        # set node2_id to "vpc" if channel IPG is vPC, otherwise "null"
        node2_id = lookup(int, "node2_id", lookup(int, "channel", null) != null ? try([for pg in local.leaf_interface_policy_group_mapping : pg.type if pg.name == lookup(int, "channel", null) && pg.type == "vpc"][0], null) : null)
        pod_id   = lookup(int, "pod_id", try([for node in lookup(local.node_policies, "nodes", []) : node.pod if node.id == int.node_id][0], local.defaults.apic.node_policies.nodes.pod))
        fex_id   = lookup(int, "fex_id", null)
        module   = lookup(int, "module", null)
        port     = lookup(int, "port", null)
        channel  = lookup(int, "channel", null) != null ? "${int.channel}${local.defaults.apic.access_policies.leaf_interface_policy_groups.name_suffix}" : null
      }]
    }]
    logical_interfaces = [for lint in lookup(device, "logical_interfaces", []) : {
      name  = "${lint.name}${local.defaults.apic.tenants.services.l4l7_devices.logical_interfaces.name_suffix}"
      alias = lookup(lint, "alias", null)
      vlan  = lint.vlan
      concrete_interfaces = lookup(lint, "concrete_interfaces", null) == null ? null : [for cint in lint.concrete_interfaces : {
        device    = cint.device
        interface = "${cint.interface_name}${local.defaults.apic.tenants.services.l4l7_devices.logical_interfaces.concrete_interfaces.name_suffix}"
      }]
    }]
  }]
}

module "aci_tenant" {
  source  = "netascode/tenant/aci"
  version = ">= 0.1.0"

  count       = lookup(local.modules, "aci_tenant", true) == false ? 0 : 1
  name        = local.tenant.name
  alias       = lookup(local.tenant, "alias", "")
  description = lookup(local.tenant, "description", "")
}

module "aci_vrf" {
  source  = "netascode/vrf/aci"
  version = ">= 0.1.0"

  for_each                    = { for vrf in lookup(local.tenant, "vrfs", []) : vrf.name => vrf if lookup(local.modules, "aci_vrf", true) }
  tenant                      = module.aci_tenant[0].name
  name                        = "${each.value.name}${local.defaults.apic.tenants.vrfs.name_suffix}"
  alias                       = lookup(each.value, "alias", "")
  description                 = lookup(each.value, "description", "")
  enforcement_direction       = lookup(each.value, "enforcement_direction", local.defaults.apic.tenants.vrfs.enforcement_direction)
  enforcement_preference      = lookup(each.value, "enforcement_preference", local.defaults.apic.tenants.vrfs.enforcement_preference)
  data_plane_learning         = lookup(each.value, "data_plane_learning", local.defaults.apic.tenants.vrfs.data_plane_learning)
  contract_consumers          = lookup(lookup(each.value, "contracts", {}), "consumers", null) != null ? [for contract in each.value.contracts.consumers : "${contract}${local.defaults.apic.tenants.contracts.name_suffix}"] : []
  contract_providers          = lookup(lookup(each.value, "contracts", {}), "providers", null) != null ? [for contract in each.value.contracts.providers : "${contract}${local.defaults.apic.tenants.contracts.name_suffix}"] : []
  contract_imported_consumers = lookup(lookup(each.value, "contracts", {}), "imported_consumers", null) != null ? [for contract in each.value.contracts.imported_consumers : "${contract}${local.defaults.apic.tenants.imported_contracts.name_suffix}"] : []
  bgp_timer_policy            = lookup(lookup(each.value, "bgp", {}), "timer_policy", null) != null ? "${each.value.bgp.timer_policy}${local.defaults.apic.tenants.policies.bgp_timer_policies.name_suffix}" : ""
  dns_labels                  = lookup(each.value, "dns_labels", [])

  depends_on = [
    module.aci_contract,
    module.aci_imported_contract,
    module.aci_bgp_timer_policy,
  ]
}

module "aci_bridge_domain" {
  source  = "netascode/bridge-domain/aci"
  version = ">= 0.1.0"

  for_each                   = { for bd in lookup(local.tenant, "bridge_domains", []) : bd.name => bd if lookup(local.modules, "aci_bridge_domain", true) }
  tenant                     = module.aci_tenant[0].name
  name                       = "${each.value.name}${local.defaults.apic.tenants.bridge_domains.name_suffix}"
  alias                      = lookup(each.value, "alias", "")
  description                = lookup(each.value, "description", "")
  arp_flooding               = lookup(each.value, "arp_flooding", local.defaults.apic.tenants.bridge_domains.arp_flooding)
  advertise_host_routes      = lookup(each.value, "advertise_host_routes", local.defaults.apic.tenants.bridge_domains.advertise_host_routes)
  ip_dataplane_learning      = lookup(each.value, "ip_dataplane_learning", local.defaults.apic.tenants.bridge_domains.ip_dataplane_learning)
  limit_ip_learn_to_subnets  = lookup(each.value, "limit_ip_learn_to_subnets", local.defaults.apic.tenants.bridge_domains.limit_ip_learn_to_subnets)
  mac                        = lookup(each.value, "mac", local.defaults.apic.tenants.bridge_domains.mac)
  l3_multicast               = lookup(each.value, "l3_multicast", local.defaults.apic.tenants.bridge_domains.l3_multicast)
  multi_destination_flooding = lookup(each.value, "multi_destination_flooding", local.defaults.apic.tenants.bridge_domains.multi_destination_flooding)
  unicast_routing            = lookup(each.value, "unicast_routing", local.defaults.apic.tenants.bridge_domains.unicast_routing)
  unknown_unicast            = lookup(each.value, "unknown_unicast", local.defaults.apic.tenants.bridge_domains.unknown_unicast)
  unknown_ipv4_multicast     = lookup(each.value, "unknown_ipv4_multicast", local.defaults.apic.tenants.bridge_domains.unknown_ipv4_multicast)
  vrf                        = "${each.value.vrf}${local.defaults.apic.tenants.vrfs.name_suffix}"
  igmp_interface_policy      = lookup(each.value, "igmp_interface_policy", null) != null ? "${each.value.igmp_interface_policy}${local.defaults.apic.tenants.policies.igmp_interface_policies.name_suffix}" : ""
  igmp_snooping_policy       = lookup(each.value, "igmp_snooping_policy", null) != null ? "${each.value.igmp_snooping_policy}${local.defaults.apic.tenants.policies.igmp_snooping_policies.name_suffix}" : ""
  subnets = [for subnet in lookup(each.value, "subnets", []) : {
    ip                 = subnet.ip
    description        = lookup(subnet, "description", "")
    primary_ip         = lookup(subnet, "primary_ip", local.defaults.apic.tenants.bridge_domains.subnets.primary_ip)
    public             = lookup(subnet, "public", local.defaults.apic.tenants.bridge_domains.subnets.public)
    shared             = lookup(subnet, "shared", local.defaults.apic.tenants.bridge_domains.subnets.shared)
    igmp_querier       = lookup(subnet, "igmp_querier", local.defaults.apic.tenants.bridge_domains.subnets.igmp_querier)
    nd_ra_prefix       = lookup(subnet, "nd_ra_prefix", local.defaults.apic.tenants.bridge_domains.subnets.nd_ra_prefix)
    no_default_gateway = lookup(subnet, "no_default_gateway", local.defaults.apic.tenants.bridge_domains.subnets.no_default_gateway)
    virtual            = lookup(subnet, "virtual", local.defaults.apic.tenants.bridge_domains.subnets.virtual)
  }]
  l3outs = lookup(each.value, "l3outs", null) != null ? [for l3out in each.value.l3outs : "${l3out}${local.defaults.apic.tenants.l3outs.name_suffix}"] : []
  dhcp_labels = [for label in lookup(each.value, "dhcp_labels", []) : {
    dhcp_relay_policy  = lookup(label, "dhcp_relay_policy", null) != null ? "${label.dhcp_relay_policy}${local.defaults.apic.tenants.policies.dhcp_relay_policies.name_suffix}" : ""
    dhcp_option_policy = lookup(label, "dhcp_option_policy", null) != null ? "${label.dhcp_option_policy}${local.defaults.apic.tenants.policies.dhcp_option_policies.name_suffix}" : ""
  }]

  depends_on = [
    module.aci_vrf,
    module.aci_l3out,
    module.aci_dhcp_relay_policy,
    module.aci_dhcp_option_policy,
  ]
}

module "aci_application_profile" {
  source  = "netascode/application-profile/aci"
  version = ">= 0.1.0"

  for_each    = { for ap in lookup(local.tenant, "application_profiles", []) : ap.name => ap if lookup(local.modules, "aci_application_profile", true) }
  tenant      = module.aci_tenant[0].name
  name        = "${each.value.name}${local.defaults.apic.tenants.application_profiles.name_suffix}"
  alias       = lookup(each.value, "alias", "")
  description = lookup(each.value, "description", "")
}

module "aci_endpoint_group" {
  source  = "netascode/endpoint-group/aci"
  version = ">= 0.1.1"

  for_each                    = { for epg in local.endpoint_groups : epg.key => epg.value if lookup(local.modules, "aci_endpoint_group", true) }
  tenant                      = module.aci_tenant[0].name
  application_profile         = module.aci_application_profile[each.value.application_profile].name
  name                        = each.value.name
  alias                       = each.value.alias
  description                 = each.value.description
  flood_in_encap              = each.value.flood_in_encap
  intra_epg_isolation         = each.value.intra_epg_isolation
  preferred_group             = each.value.preferred_group
  bridge_domain               = each.value.bridge_domain
  contract_consumers          = each.value.contract_consumers
  contract_providers          = each.value.contract_providers
  contract_imported_consumers = each.value.contract_imported_consumers
  physical_domains            = each.value.physical_domains
  static_ports = [for sp in lookup(each.value, "static_ports", []) : {
    node_id              = sp.node_id
    node2_id             = sp.node2_id == "vpc" ? [for pg in local.leaf_interface_policy_group_mapping : lookup(pg, "node_ids", []) if pg.name == sp.channel][0][1] : sp.node2_id
    pod_id               = sp.pod_id != null ? sp.pod_id : try([for node in lookup(local.node_policies, "nodes", []) : node.pod if node.id == sp.node_id][0], local.defaults.apic.node_policies.nodes.pod)
    channel              = sp.channel
    port                 = sp.port
    sub_port             = sp.sub_port
    module               = sp.module
    vlan                 = sp.vlan
    deployment_immediacy = sp.deployment_immediacy
    mode                 = sp.mode
  }]
  vmware_vmm_domains = each.value.vmware_vmm_domains
  subnets            = each.value.subnets

  depends_on = [
    module.aci_bridge_domain,
    module.aci_contract,
    module.aci_imported_contract,
  ]
}

module "aci_inband_endpoint_group" {
  source  = "netascode/inband-endpoint-group/aci"
  version = ">= 0.1.0"

  for_each                    = { for epg in lookup(local.tenant, "inb_endpoint_groups", []) : epg.name => epg if local.tenant.name == "mgmt" && lookup(local.modules, "aci_inband_endpoint_group", true) }
  name                        = "${each.value.name}${local.defaults.apic.tenants.inb_endpoint_groups.name_suffix}"
  vlan                        = each.value.vlan
  bridge_domain               = "${each.value.bridge_domain}${local.defaults.apic.tenants.bridge_domains.name_suffix}"
  contract_consumers          = lookup(lookup(each.value, "contracts", null), "consumers", null) != null ? [for contract in each.value.contracts.consumers : "${contract}${local.defaults.apic.tenants.contracts.name_suffix}"] : []
  contract_providers          = lookup(lookup(each.value, "contracts", null), "providers", null) != null ? [for contract in each.value.contracts.providers : "${contract}${local.defaults.apic.tenants.contracts.name_suffix}"] : []
  contract_imported_consumers = lookup(lookup(each.value, "contracts", null), "imported_consumers", null) != null ? [for contract in each.value.contracts.imported_consumers : "${contract}${local.defaults.apic.tenants.imported_contracts.name_suffix}"] : []

  depends_on = [
    module.aci_contract,
    module.aci_imported_contract,
    module.aci_bridge_domain,
  ]
}

module "aci_oob_endpoint_group" {
  source  = "netascode/oob-endpoint-group/aci"
  version = ">= 0.1.0"

  for_each               = { for epg in lookup(local.tenant, "oob_endpoint_groups", []) : epg.name => epg if local.tenant.name == "mgmt" && lookup(local.modules, "aci_oob_endpoint_group", true) }
  name                   = "${each.value.name}${local.defaults.apic.tenants.oob_endpoint_groups.name_suffix}"
  oob_contract_providers = lookup(lookup(each.value, "oob_contracts", {}), "providers", null) != null ? [for contract in each.value.oob_contracts.providers : "${contract}${local.defaults.apic.tenants.oob_contracts.name_suffix}"] : []

  depends_on = [
    module.aci_oob_contract,
  ]
}

module "aci_oob_ext_mgmt_instance" {
  source  = "netascode/oob-external-management-instance/aci"
  version = ">= 0.1.0"

  for_each               = { for ext in lookup(local.tenant, "ext_mgmt_instances", []) : ext.name => ext if local.tenant.name == "mgmt" && lookup(local.modules, "aci_oob_ext_mgmt_instance", true) }
  name                   = "${each.value.name}${local.defaults.apic.tenants.ext_mgmt_instances.name_suffix}"
  subnets                = lookup(each.value, "subnets", [])
  oob_contract_consumers = lookup(lookup(each.value, "oob_contracts", {}), "consumers", null) != null ? [for contract in each.value.oob_contracts.consumers : "${contract}${local.defaults.apic.tenants.oob_contracts.name_suffix}"] : []

  depends_on = [
    module.aci_oob_contract,
  ]
}

module "aci_l3out" {
  source  = "netascode/l3out/aci"
  version = ">= 0.1.0"

  for_each                     = { for l3out in local.l3outs : l3out.name => l3out if lookup(local.modules, "aci_l3out", true) }
  tenant                       = module.aci_tenant[0].name
  name                         = each.value.name
  alias                        = each.value.alias
  description                  = each.value.description
  routed_domain                = each.value.domain
  vrf                          = each.value.vrf
  bgp                          = each.value.bgp
  ospf                         = each.value.ospf
  ospf_area                    = each.value.ospf_area
  ospf_area_cost               = each.value.ospf_area_cost
  ospf_area_type               = each.value.ospf_area_type
  import_route_map_description = each.value.import_route_map_description
  import_route_map_type        = each.value.import_route_map_type
  import_route_map_contexts    = each.value.import_route_map_contexts
  export_route_map_description = each.value.export_route_map_description
  export_route_map_type        = each.value.export_route_map_type
  export_route_map_contexts    = each.value.export_route_map_contexts

  depends_on = [
    module.aci_vrf,
    module.aci_ospf_interface_policy,
    module.aci_bfd_interface_policy,
    module.aci_set_rule,
    module.aci_match_rule,
  ]
}

module "aci_l3out_node_profile_manual" {
  source  = "netascode/l3out-node-profile/aci"
  version = ">= 0.1.0"

  for_each = { for np in local.node_profiles_manual : np.key => np.value if lookup(local.modules, "aci_l3out_node_profile", true) }
  tenant   = module.aci_tenant[0].name
  l3out    = each.value.l3out
  name     = each.value.name
  nodes    = each.value.nodes

  depends_on = [
    module.aci_l3out,
  ]
}

module "aci_l3out_node_profile_auto" {
  source  = "netascode/l3out-node-profile/aci"
  version = ">= 0.1.0"

  for_each = { for np in local.node_profiles_auto : np.name => np if lookup(local.modules, "aci_l3out_node_profile", true) }
  tenant   = module.aci_tenant[0].name
  l3out    = each.value.l3out
  name     = each.value.name
  nodes    = each.value.nodes

  depends_on = [
    module.aci_l3out,
  ]
}

module "aci_l3out_interface_profile_manual" {
  source  = "netascode/l3out-interface-profile/aci"
  version = ">= 0.1.0"

  for_each                    = { for ip in local.interface_profiles_manual : ip.key => ip.value if lookup(local.modules, "aci_l3out_interface_profile", true) }
  tenant                      = module.aci_tenant[0].name
  l3out                       = each.value.l3out
  node_profile                = each.value.node_profile
  name                        = each.value.name
  bfd_policy                  = each.value.bfd_policy
  ospf_interface_profile_name = each.value.ospf_interface_profile_name
  ospf_authentication_key     = each.value.ospf_authentication_key
  ospf_authentication_key_id  = each.value.ospf_authentication_key_id
  ospf_authentication_type    = each.value.ospf_authentication_type
  ospf_interface_policy       = each.value.ospf_interface_policy
  interfaces = each.value.interfaces == null ? null : [for int in lookup(each.value, "interfaces", []) : {
    ip          = int.ip
    svi         = int.svi
    vlan        = int.vlan
    description = int.description
    type        = int.type
    mac         = int.mac
    mtu         = int.mtu
    node_id     = int.node_id
    node2_id    = int.node2_id == "vpc" ? [for pg in local.leaf_interface_policy_group_mapping : lookup(pg, "node_ids", []) if pg.name == int.channel][0][1] : int.node2_id
    pod_id      = int.pod_id != null ? int.pod_id : try([for node in lookup(local.node_policies, "nodes", []) : node.pod if node.id == int.node_id][0], local.defaults.apic.tenants.l3outs.node_profiles.interface_profiles.interfaces.pod)
    module      = int.module
    port        = int.port
    channel     = int.channel
    ip_a        = int.ip_a
    ip_b        = int.ip_b
    ip_shared   = int.ip_shared
    bgp_peers   = int.bgp_peers
  }]

  depends_on = [
    module.aci_l3out_node_profile_manual,
  ]
}

module "aci_l3out_interface_profile_auto" {
  source  = "netascode/l3out-interface-profile/aci"
  version = ">= 0.1.0"

  for_each                    = { for ip in local.interface_profiles_auto : ip.name => ip if lookup(local.modules, "aci_l3out_interface_profile", true) }
  tenant                      = module.aci_tenant[0].name
  l3out                       = each.value.l3out
  node_profile                = each.value.node_profile
  name                        = each.value.name
  bfd_policy                  = each.value.bfd_policy
  ospf_interface_profile_name = each.value.ospf_interface_profile_name
  ospf_authentication_key     = each.value.ospf_authentication_key
  ospf_authentication_key_id  = each.value.ospf_authentication_key_id
  ospf_authentication_type    = each.value.ospf_authentication_type
  ospf_interface_policy       = each.value.ospf_interface_policy
  interfaces = each.value.interfaces == null ? null : [for int in lookup(each.value, "interfaces", []) : {
    ip          = int.ip
    svi         = int.svi
    vlan        = int.vlan
    description = int.description
    type        = int.type
    mac         = int.mac
    mtu         = int.mtu
    node_id     = int.node_id
    node2_id    = int.node2_id == "vpc" ? [for pg in local.leaf_interface_policy_group_mapping : lookup(pg, "node_ids", []) if pg.name == int.channel][0][1] : int.node2_id
    pod_id      = int.pod_id != null ? int.pod_id : try([for node in lookup(local.node_policies, "nodes", []) : node.pod if node.id == int.node_id][0], local.defaults.apic.tenants.l3outs.nodes.interfaces.pod)
    module      = int.module
    port        = int.port
    channel     = int.channel
    ip_a        = int.ip_a
    ip_b        = int.ip_b
    ip_shared   = int.ip_shared
    bgp_peers   = int.bgp_peers
  }]

  depends_on = [
    module.aci_l3out_node_profile_auto,
  ]
}

module "aci_external_endpoint_group" {
  source  = "netascode/external-endpoint-group/aci"
  version = ">= 0.1.0"

  for_each                    = { for epg in local.external_endpoint_groups : epg.key => epg.value if lookup(local.modules, "aci_external_endpoint_group", true) }
  tenant                      = module.aci_tenant[0].name
  l3out                       = module.aci_l3out[each.value.l3out].name
  name                        = each.value.name
  alias                       = each.value.alias
  description                 = each.value.description
  preferred_group             = each.value.preferred_group
  contract_consumers          = each.value.contract_consumers
  contract_providers          = each.value.contract_providers
  contract_imported_consumers = each.value.contract_imported_consumers
  subnets                     = each.value.subnets

  depends_on = [
    module.aci_contract,
    module.aci_imported_contract,
  ]
}

module "aci_filter" {
  source  = "netascode/filter/aci"
  version = ">= 0.1.0"

  for_each    = { for filter in lookup(local.tenant, "filters", []) : filter.name => filter if lookup(local.modules, "aci_filter", true) }
  tenant      = module.aci_tenant[0].name
  name        = "${each.value.name}${local.defaults.apic.tenants.filters.name_suffix}"
  alias       = lookup(each.value, "alias", "")
  description = lookup(each.value, "description", "")
  entries = [for entry in lookup(each.value, "entries", []) : {
    name                  = "${entry.name}${local.defaults.apic.tenants.filters.entries.name_suffix}"
    alias                 = lookup(entry, "alias", "")
    description           = lookup(entry, "description", "")
    ethertype             = lookup(entry, "ethertype", local.defaults.apic.tenants.filters.entries.ethertype)
    protocol              = lookup(entry, "protocol", local.defaults.apic.tenants.filters.entries.protocol)
    source_from_port      = lookup(entry, "source_from_port", local.defaults.apic.tenants.filters.entries.source_from_port)
    source_to_port        = lookup(entry, "source_to_port", lookup(entry, "source_from_port", local.defaults.apic.tenants.filters.entries.source_to_port))
    destination_from_port = lookup(entry, "destination_from_port", local.defaults.apic.tenants.filters.entries.destination_from_port)
    destination_to_port   = lookup(entry, "destination_to_port", lookup(entry, "destination_from_port", local.defaults.apic.tenants.filters.entries.destination_to_port))
    stateful              = lookup(entry, "stateful", local.defaults.apic.tenants.filters.entries.stateful)
  }]
}

module "aci_contract" {
  source  = "netascode/contract/aci"
  version = ">= 0.1.0"

  for_each    = { for contract in lookup(local.tenant, "contracts", []) : contract.name => contract if lookup(local.modules, "aci_contract", true) }
  tenant      = module.aci_tenant[0].name
  name        = "${each.value.name}${local.defaults.apic.tenants.contracts.name_suffix}"
  alias       = lookup(each.value, "alias", "")
  description = lookup(each.value, "description", "")
  scope       = lookup(each.value, "scope", local.defaults.apic.tenants.contracts.scope)
  subjects = [for subject in lookup(each.value, "subjects", []) : {
    name          = "${subject.name}${local.defaults.apic.tenants.contracts.subjects.name_suffix}"
    alias         = lookup(subject, "alias", "")
    description   = lookup(subject, "description", "")
    service_graph = lookup(subject, "service_graph", null) != null ? "${subject.service_graph}${local.defaults.apic.tenants.services.service_graph_templates.name_suffix}" : ""
    filters = [for filter in lookup(subject, "filters", []) : {
      filter   = "${filter.filter}${local.defaults.apic.tenants.filters.name_suffix}"
      action   = lookup(filter, "action", local.defaults.apic.tenants.contracts.subjects.filters.action)
      priority = lookup(filter, "priority", local.defaults.apic.tenants.contracts.subjects.filters.priority)
      log      = lookup(filter, "log", local.defaults.apic.tenants.contracts.subjects.filters.log)
      no_stats = lookup(filter, "no_stats", local.defaults.apic.tenants.contracts.subjects.filters.no_stats)
    }]
  }]

  depends_on = [
    module.aci_filter,
  ]
}

module "aci_oob_contract" {
  source  = "netascode/oob-contract/aci"
  version = ">= 0.1.0"

  for_each    = { for contract in lookup(local.tenant, "oob_contracts", []) : contract.name => contract if local.tenant.name == "mgmt" && lookup(local.modules, "aci_oob_contract", true) }
  name        = "${each.value.name}${local.defaults.apic.tenants.oob_contracts.name_suffix}"
  alias       = lookup(each.value, "alias", "")
  description = lookup(each.value, "description", "")
  scope       = lookup(each.value, "scope", local.defaults.apic.tenants.oob_contracts.scope)
  subjects = [for subject in lookup(each.value, "subjects", []) : {
    name        = "${subject.name}${local.defaults.apic.tenants.oob_contracts.subjects.name_suffix}"
    alias       = lookup(subject, "alias", "")
    description = lookup(subject, "description", "")
    filters = [for filter in lookup(subject, "filters", []) : {
      filter = "${filter.filter}${local.defaults.apic.tenants.filters.name_suffix}"
    }]
  }]

  depends_on = [
    module.aci_filter,
  ]
}

module "aci_imported_contract" {
  source  = "netascode/imported-contract/aci"
  version = ">= 0.1.0"

  for_each        = { for contract in lookup(local.tenant, "imported_contracts", []) : contract.name => contract if lookup(local.modules, "aci_imported_contract", true) }
  tenant          = module.aci_tenant[0].name
  name            = "${each.value.name}${local.defaults.apic.tenants.imported_contracts.name_suffix}"
  source_contract = "${each.value.contract}${local.defaults.apic.tenants.contracts.name_suffix}"
  source_tenant   = each.value.tenant
}

module "aci_ospf_interface_policy" {
  source  = "netascode/ospf-interface-policy/aci"
  version = ">= 0.1.0"

  for_each                = { for policy in lookup(lookup(local.tenant, "policies", {}), "ospf_interface_policies", []) : policy.name => policy if lookup(local.modules, "aci_ospf_interface_policy", true) }
  tenant                  = module.aci_tenant[0].name
  name                    = "${each.value.name}${local.defaults.apic.tenants.policies.ospf_interface_policies.name_suffix}"
  description             = lookup(each.value, "description", "")
  cost                    = lookup(each.value, "cost", local.defaults.apic.tenants.policies.ospf_interface_policies.cost)
  dead_interval           = lookup(each.value, "dead_interval", local.defaults.apic.tenants.policies.ospf_interface_policies.dead_interval)
  hello_interval          = lookup(each.value, "hello_interval", local.defaults.apic.tenants.policies.ospf_interface_policies.hello_interval)
  network_type            = lookup(each.value, "network_type", local.defaults.apic.tenants.policies.ospf_interface_policies.network_type)
  priority                = lookup(each.value, "priority", local.defaults.apic.tenants.policies.ospf_interface_policies.priority)
  lsa_retransmit_interval = lookup(each.value, "lsa_retransmit_interval", local.defaults.apic.tenants.policies.ospf_interface_policies.lsa_retransmit_interval)
  lsa_transmit_delay      = lookup(each.value, "lsa_transmit_delay", local.defaults.apic.tenants.policies.ospf_interface_policies.lsa_transmit_delay)
  passive_interface       = lookup(each.value, "passive_interface", local.defaults.apic.tenants.policies.ospf_interface_policies.passive_interface)
  mtu_ignore              = lookup(each.value, "mtu_ignore", local.defaults.apic.tenants.policies.ospf_interface_policies.mtu_ignore)
  advertise_subnet        = lookup(each.value, "advertise_subnet", local.defaults.apic.tenants.policies.ospf_interface_policies.advertise_subnet)
  bfd                     = lookup(each.value, "bfd", local.defaults.apic.tenants.policies.ospf_interface_policies.bfd)
}

module "aci_bgp_timer_policy" {
  source  = "netascode/bgp-timer-policy/aci"
  version = ">= 0.1.0"

  for_each                = { for pol in lookup(lookup(local.tenant, "policies", {}), "bgp_timer_policies", []) : pol.name => pol if lookup(local.modules, "aci_bgp_timer_policy", true) }
  tenant                  = module.aci_tenant[0].name
  name                    = "${each.value.name}${local.defaults.apic.tenants.policies.bgp_timer_policies.name_suffix}"
  description             = lookup(each.value, "description", "")
  graceful_restart_helper = lookup(each.value, "graceful_restart_helper", local.defaults.apic.tenants.policies.bgp_timer_policies.graceful_restart_helper)
  hold_interval           = lookup(each.value, "hold_interval", local.defaults.apic.tenants.policies.bgp_timer_policies.hold_interval)
  keepalive_interval      = lookup(each.value, "keepalive_interval", local.defaults.apic.tenants.policies.bgp_timer_policies.keepalive_interval)
  maximum_as_limit        = lookup(each.value, "maximum_as_limit", local.defaults.apic.tenants.policies.bgp_timer_policies.maximum_as_limit)
  stale_interval          = lookup(each.value, "stale_interval", local.defaults.apic.tenants.policies.bgp_timer_policies.stale_interval)
}

module "aci_dhcp_relay_policy" {
  source  = "netascode/dhcp-relay-policy/aci"
  version = ">= 0.1.0"

  for_each    = { for policy in lookup(lookup(local.tenant, "policies", {}), "dhcp_relay_policies", []) : policy.name => policy if lookup(local.modules, "aci_dhcp_relay_policy", true) }
  tenant      = module.aci_tenant[0].name
  name        = "${each.value.name}${local.defaults.apic.tenants.policies.dhcp_relay_policies.name_suffix}"
  description = lookup(each.value, "description", "")
  providers_ = [for provider in lookup(each.value, "providers", []) : {
    ip                      = provider.ip
    type                    = provider.type
    tenant                  = lookup(provider, "tenant", local.tenant.name)
    application_profile     = lookup(provider, "application_profile", null) != null ? "${provider.application_profile}${local.defaults.apic.tenants.application_profiles.name_suffix}" : ""
    endpoint_group          = lookup(provider, "endpoint_group", null) != null ? "${provider.endpoint_group}${local.defaults.apic.tenants.application_profiles.endpoint_groups.name_suffix}" : ""
    l3out                   = lookup(provider, "l3out", null) != null ? "${provider.l3ou}${local.defaults.apic.tenants.l3outs.name_suffix}" : ""
    external_endpoint_group = lookup(provider, "external_endpoint_group", null) != null ? "${provider.external_endpoint_group}${local.defaults.apic.tenants.l3outs.external_endpoint_groups.name_suffix}" : ""
  }]
}

module "aci_dhcp_option_policy" {
  source  = "netascode/dhcp-option-policy/aci"
  version = ">= 0.1.0"

  for_each    = { for policy in lookup(lookup(local.tenant, "policies", {}), "dhcp_option_policies", []) : policy.name => policy if lookup(local.modules, "aci_dhcp_option_policy", true) }
  tenant      = module.aci_tenant[0].name
  name        = "${each.value.name}${local.defaults.apic.tenants.policies.dhcp_option_policies.name_suffix}"
  description = lookup(each.value, "description", "")
  options     = lookup(each.value, "options", [])
}

module "aci_match_rule" {
  source  = "netascode/match-rule/aci"
  version = ">= 0.1.0"

  for_each    = { for rule in lookup(lookup(local.tenant, "policies", {}), "match_rules", []) : rule.name => rule if lookup(local.modules, "aci_match_rule", true) }
  tenant      = module.aci_tenant[0].name
  name        = "${each.value.name}${local.defaults.apic.tenants.policies.match_rules.name_suffix}"
  description = lookup(each.value, "description", "")
  prefixes = [for prefix in lookup(each.value, "prefixes", []) : {
    ip          = prefix.ip
    aggregate   = lookup(prefix, "aggregate", local.defaults.apic.tenants.policies.match_rules.prefixes.aggregate)
    description = lookup(prefix, "description", "")
    from_length = lookup(prefix, "from_length", local.defaults.apic.tenants.policies.match_rules.prefixes.from_length)
    to_length   = lookup(prefix, "to_length", local.defaults.apic.tenants.policies.match_rules.prefixes.to_length)
  }]
}

module "aci_set_rule" {
  source  = "netascode/set-rule/aci"
  version = ">= 0.1.0"

  for_each       = { for rule in lookup(lookup(local.tenant, "policies", {}), "set_rules", []) : rule.name => rule if lookup(local.modules, "aci_set_rule", true) }
  tenant         = module.aci_tenant[0].name
  name           = "${each.value.name}${local.defaults.apic.tenants.policies.set_rules.name_suffix}"
  description    = lookup(each.value, "description", "")
  community      = each.value.community
  community_mode = lookup(each.value, "community_mode", local.defaults.apic.tenants.policies.set_rules.community_mode)
}

module "aci_bfd_interface_policy" {
  source  = "netascode/bfd-interface-policy/aci"
  version = ">= 0.1.0"

  for_each                  = { for pol in lookup(lookup(local.tenant, "policies", {}), "bfd_interface_policies", []) : pol.name => pol if lookup(local.modules, "aci_bfd_interface_policy", true) }
  tenant                    = module.aci_tenant[0].name
  name                      = "${each.value.name}${local.defaults.apic.tenants.policies.bfd_interface_policies.name_suffix}"
  description               = lookup(each.value, "description", "")
  subinterface_optimization = lookup(each.value, "subinterface_optimization", local.defaults.apic.tenants.policies.bfd_interface_policies.subinterface_optimization)
  detection_multiplier      = lookup(each.value, "detection_multiplier", local.defaults.apic.tenants.policies.bfd_interface_policies.detection_multiplier)
  echo_admin_state          = lookup(each.value, "echo_admin_state", local.defaults.apic.tenants.policies.bfd_interface_policies.echo_admin_state)
  echo_rx_interval          = lookup(each.value, "echo_rx_interval", local.defaults.apic.tenants.policies.bfd_interface_policies.echo_rx_interval)
  min_rx_interval           = lookup(each.value, "min_rx_interval", local.defaults.apic.tenants.policies.bfd_interface_policies.min_rx_interval)
  min_tx_interval           = lookup(each.value, "min_tx_interval", local.defaults.apic.tenants.policies.bfd_interface_policies.min_tx_interval)
}

module "aci_l4l7_device" {
  source  = "netascode/l4l7-device/aci"
  version = ">= 0.1.0"

  for_each         = { for device in local.l4l7_devices : device.name => device if lookup(local.modules, "aci_l4l7_device", true) }
  tenant           = module.aci_tenant[0].name
  name             = each.value.name
  alias            = each.value.alias
  context_aware    = each.value.context_aware
  type             = each.value.type
  function         = each.value.function
  copy_device      = each.value.copy_device
  managed          = each.value.managed
  promiscuous_mode = each.value.promiscuous_mode
  service_type     = each.value.service_type
  trunking         = each.value.trunking
  physical_domain  = each.value.physical_domain
  concrete_devices = [for cdev in lookup(each.value, "concrete_devices", []) : {
    name         = cdev.name
    alias        = cdev.alias
    description  = cdev.description
    vcenter_name = cdev.vcenter_name
    vm_name      = cdev.vm_name
    interfaces = [for int in lookup(cdev, "interfaces", []) : {
      name      = int.name
      alias     = int.alias
      vnic_name = int.vnic_name
      node_id   = int.node_id
      node2_id  = int.node2_id == "vpc" ? [for pg in local.leaf_interface_policy_group_mapping : lookup(pg, "node_ids", []) if pg.name == int.channel][0][1] : int.node2_id
      pod_id    = int.pod_id
      fex_id    = int.fex_id
      module    = int.module
      port      = int.port
      channel   = int.channel
    }]
  }]
  logical_interfaces = each.value.logical_interfaces
}

module "aci_redirect_policy" {
  source  = "netascode/redirect-policy/aci"
  version = ">= 0.1.0"

  for_each              = { for policy in lookup(lookup(local.tenant, "services", {}), "redirect_policies", []) : policy.name => policy if lookup(local.modules, "aci_redirect_policy", true) }
  tenant                = module.aci_tenant[0].name
  name                  = "${each.value.name}${local.defaults.apic.tenants.services.redirect_policies.name_suffix}"
  alias                 = lookup(each.value, "alias", "")
  description           = lookup(each.value, "description", "")
  anycast               = lookup(each.value, "anycast", local.defaults.apic.tenants.services.redirect_policies.anycast)
  type                  = lookup(each.value, "type", local.defaults.apic.tenants.services.redirect_policies.type)
  hashing               = lookup(each.value, "hashing", local.defaults.apic.tenants.services.redirect_policies.hashing)
  threshold             = lookup(each.value, "threshold", local.defaults.apic.tenants.services.redirect_policies.threshold)
  max_threshold         = lookup(each.value, "max_threshold", local.defaults.apic.tenants.services.redirect_policies.max_threshold)
  min_threshold         = lookup(each.value, "min_threshold", local.defaults.apic.tenants.services.redirect_policies.min_threshold)
  pod_aware             = lookup(each.value, "pod_aware", local.defaults.apic.tenants.services.redirect_policies.pod_aware)
  resilient_hashing     = lookup(each.value, "resilient_hashing", local.defaults.apic.tenants.services.redirect_policies.resilient_hashing)
  threshold_down_action = lookup(each.value, "threshold_down_action", local.defaults.apic.tenants.services.redirect_policies.threshold_down_action)
  l3_destinations = [for dest in lookup(each.value, "l3_destinations", []) : {
    description = lookup(dest, "description", "")
    ip          = dest.ip
    ip_2        = lookup(dest, "ip_2", null)
    mac         = dest.mac
    pod_id      = lookup(dest, "pod", local.defaults.apic.tenants.services.redirect_policies.l3_destinations.pod)
  }]
}

module "aci_service_graph_template" {
  source  = "netascode/service-graph-template/aci"
  version = ">= 0.1.0"

  for_each            = { for sg_template in lookup(lookup(local.tenant, "services", {}), "service_graph_templates", []) : sg_template.name => sg_template if lookup(local.modules, "aci_service_graph_template", true) }
  tenant              = module.aci_tenant[0].name
  name                = "${each.value.name}${local.defaults.apic.tenants.services.service_graph_templates.name_suffix}"
  description         = lookup(each.value, "description", "")
  alias               = lookup(each.value, "alias", "")
  template_type       = lookup(each.value, "template_type", local.defaults.apic.tenants.services.service_graph_templates.template_type)
  redirect            = lookup(each.value, "redirect", local.defaults.apic.tenants.services.service_graph_templates.redirect)
  share_encapsulation = lookup(each.value, "share_encapsulation", local.defaults.apic.tenants.services.service_graph_templates.share_encapsulation)
  device_name         = "${each.value.device.name}${local.defaults.apic.tenants.services.l4l7_devices.name_suffix}"
  device_tenant       = lookup(each.value.device, "tenant", null)
  device_function     = length(local.l4l7_devices) != 0 ? [for device in local.l4l7_devices : lookup(device, "function", []) if device.name == each.value.device.name][0] : "None"
  device_copy         = (length(local.l4l7_devices) != 0 ? [for device in local.l4l7_devices : lookup(device, "copy_device", []) if device.name == each.value.device.name][0] : false)
  device_managed      = (length(local.l4l7_devices) != 0 ? [for device in local.l4l7_devices : lookup(device, "managed", []) if device.name == each.value.device.name][0] : false)

  depends_on = [
    module.aci_l4l7_device,
  ]
}

module "aci_device_selection_policy" {
  source  = "netascode/device-selection-policy/aci"
  version = ">= 0.1.0"

  for_each                                                = { for pol in lookup(lookup(local.tenant, "services", {}), "device_selection_policies", []) : "${pol.contract}/${pol.service_graph_template}" => pol if lookup(local.modules, "aci_device_selection_policy", true) }
  tenant                                                  = module.aci_tenant[0].name
  contract                                                = "${each.value.contract}${local.defaults.apic.tenants.contracts.name_suffix}"
  service_graph_template                                  = "${each.value.service_graph_template}${local.defaults.apic.tenants.services.service_graph_templates.name_suffix}"
  sgt_device_tenant                                       = length(lookup(lookup(local.tenant, "services", {}), "service_graph_templates", [])) != 0 ? [for sg_template in lookup(lookup(local.tenant, "services", {}), "service_graph_templates", []) : lookup(sg_template.device, "tenant", null) if sg_template.name == each.value.service_graph_template][0] : ""
  sgt_device_name                                         = length(lookup(lookup(local.tenant, "services", {}), "service_graph_templates", [])) != 0 ? [for sg_template in lookup(lookup(local.tenant, "services", {}), "service_graph_templates", []) : "${sg_template.device.name}${local.defaults.apic.tenants.services.l4l7_devices.name_suffix}" if sg_template.name == each.value.service_graph_template][0] : ""
  consumer_l3_destination                                 = lookup(each.value.consumer, "l3_destination", local.defaults.apic.tenants.services.device_selection_policies.consumer.l3_destination)
  consumer_permit_logging                                 = lookup(each.value.consumer, "permit_logging", local.defaults.apic.tenants.services.device_selection_policies.consumer.permit_logging)
  consumer_logical_interface                              = "${each.value.consumer.logical_interface}${local.defaults.apic.tenants.services.l4l7_devices.logical_interfaces.name_suffix}"
  consumer_redirect_policy                                = lookup(each.value.consumer, "redirect_policy", null) != null ? "${each.value.consumer.redirect_policy.name}${local.defaults.apic.tenants.services.redirect_policies.name_suffix}" : ""
  consumer_redirect_policy_tenant                         = lookup(lookup(each.value.consumer, "redirect_policy", {}), "tenant", "")
  consumer_bridge_domain                                  = lookup(each.value.consumer, "bridge_domain", null) != null ? "${each.value.consumer.bridge_domain.name}${local.defaults.apic.tenants.bridge_domains.name_suffix}" : ""
  consumer_bridge_domain_tenant                           = lookup(lookup(each.value.consumer, "bridge_domain", {}), "tenant", null)
  consumer_external_endpoint_group                        = lookup(each.value.consumer, "external_endpoint_group", null) != null ? "${each.value.consumer.external_endpoint_group.name}${local.defaults.apic.tenants.l3outs.external_endpoint_groups.name_suffix}" : ""
  consumer_external_endpoint_group_l3out                  = lookup(each.value.consumer, "external_endpoint_group", null) != null ? "${each.value.consumer.external_endpoint_group.l3out}${local.defaults.apic.tenants.l3outs.name_suffix}" : ""
  consumer_external_endpoint_group_tenant                 = lookup(lookup(each.value.consumer, "external_endpoint_group", {}), "tenant", "")
  consumer_external_endpoint_group_redistribute_bgp       = lookup(lookup(lookup(each.value.consumer, "external_endpoint_group", {}), "redistribute", {}), "bgp", "${local.defaults.apic.tenants.services.device_selection_policies.consumer.external_endpoint_group.redistribute.bgp}")
  consumer_external_endpoint_group_redistribute_ospf      = lookup(lookup(lookup(each.value.consumer, "external_endpoint_group", {}), "redistribute", {}), "ospf", "${local.defaults.apic.tenants.services.device_selection_policies.consumer.external_endpoint_group.redistribute.ospf}")
  consumer_external_endpoint_group_redistribute_connected = lookup(lookup(lookup(each.value.consumer, "external_endpoint_group", {}), "redistribute", {}), "connected", "${local.defaults.apic.tenants.services.device_selection_policies.consumer.external_endpoint_group.redistribute.connected}")
  consumer_external_endpoint_group_redistribute_static    = lookup(lookup(lookup(each.value.consumer, "external_endpoint_group", {}), "redistribute", {}), "static", "${local.defaults.apic.tenants.services.device_selection_policies.consumer.external_endpoint_group.redistribute.static}")
  provider_l3_destination                                 = lookup(each.value.provider, "l3_destination", local.defaults.apic.tenants.services.device_selection_policies.provider.l3_destination)
  provider_permit_logging                                 = lookup(each.value.provider, "permit_logging", local.defaults.apic.tenants.services.device_selection_policies.provider.permit_logging)
  provider_logical_interface                              = "${each.value.provider.logical_interface}${local.defaults.apic.tenants.services.l4l7_devices.logical_interfaces.name_suffix}"
  provider_redirect_policy                                = lookup(each.value.provider, "redirect_policy", null) != null ? "${each.value.provider.redirect_policy.name}${local.defaults.apic.tenants.services.redirect_policies.name_suffix}" : ""
  provider_redirect_policy_tenant                         = lookup(lookup(each.value.provider, "redirect_policy", {}), "tenant", "")
  provider_bridge_domain                                  = lookup(each.value.provider, "bridge_domain", null) != null ? "${each.value.provider.bridge_domain.name}${local.defaults.apic.tenants.bridge_domains.name_suffix}" : ""
  provider_bridge_domain_tenant                           = lookup(lookup(each.value.provider, "bridge_domain", {}), "tenant", null)
  provider_external_endpoint_group                        = lookup(each.value.provider, "external_endpoint_group", null) != null ? "${each.value.provider.external_endpoint_group.name}${local.defaults.apic.tenants.l3outs.external_endpoint_groups.name_suffix}" : ""
  provider_external_endpoint_group_l3out                  = lookup(each.value.provider, "external_endpoint_group", null) != null ? "${each.value.provider.external_endpoint_group.l3out}${local.defaults.apic.tenants.l3outs.name_suffix}" : ""
  provider_external_endpoint_group_tenant                 = lookup(lookup(each.value.provider, "external_endpoint_group", {}), "tenant", "")
  provider_external_endpoint_group_redistribute_bgp       = lookup(lookup(lookup(each.value.provider, "external_endpoint_group", {}), "redistribute", {}), "bgp", "${local.defaults.apic.tenants.services.device_selection_policies.provider.external_endpoint_group.redistribute.bgp}")
  provider_external_endpoint_group_redistribute_ospf      = lookup(lookup(lookup(each.value.provider, "external_endpoint_group", {}), "redistribute", {}), "ospf", "${local.defaults.apic.tenants.services.device_selection_policies.provider.external_endpoint_group.redistribute.ospf}")
  provider_external_endpoint_group_redistribute_connected = lookup(lookup(lookup(each.value.provider, "external_endpoint_group", {}), "redistribute", {}), "connected", "${local.defaults.apic.tenants.services.device_selection_policies.provider.external_endpoint_group.redistribute.connected}")
  provider_external_endpoint_group_redistribute_static    = lookup(lookup(lookup(each.value.provider, "external_endpoint_group", {}), "redistribute", {}), "static", "${local.defaults.apic.tenants.services.device_selection_policies.provider.external_endpoint_group.redistribute.static}")

  depends_on = [
    module.aci_l4l7_device,
    module.aci_service_graph_template,
    module.aci_redirect_policy,
    module.aci_contract,
    module.aci_bridge_domain,
    module.aci_external_endpoint_group,
  ]
}
