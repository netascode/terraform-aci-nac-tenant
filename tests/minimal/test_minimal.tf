terraform {
  required_version = ">= 1.3.0"

  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aci = {
      source  = "CiscoDevNet/aci"
      version = ">=2.0.0"
    }
  }
}

module "main" {
  source = "../.."

  model = {
    apic = {
      tenants = [
        {
          name = "TENANT1"
        }
      ]
    }
  }
  tenant_name = "TENANT1"
}

data "aci_rest_managed" "fvTenant" {
  dn = "uni/tn-TENANT1"

  depends_on = [module.main]
}

resource "test_assertions" "fvTenant" {
  component = "fvTenant"

  equal "name" {
    description = "name"
    got         = data.aci_rest_managed.fvTenant.content.name
    want        = "TENANT1"
  }
}
