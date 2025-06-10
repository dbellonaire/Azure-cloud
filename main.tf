# Create the resource group
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "rg-webapp"
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "webappPlan-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp" {
  name                  = "webappService${var.prefix}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true
  site_config { 
     minimum_tls_version = "1.2"
     default_documents = ["Home.html"]
     app_command_line = "cp /home/default /etc/nginx/sites-enabled/default; service nginx restart"
  application_stack { 
  php_version = "8.2"
  }   
  }

}
#  Deploy code from a repo
resource "azurerm_app_service_source_control" "sourcecontrol" {
  app_id             = azurerm_linux_web_app.webapp.id
  repo_url           = "https://dennisbello@dev.azure.com/dennisbello/docs.novatel.com/_git/web_app_docs"
  branch             = "main"
  use_manual_integration = true
  use_mercurial      = false        
}

