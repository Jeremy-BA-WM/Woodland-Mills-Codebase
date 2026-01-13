using System;

namespace LeadTime
{
    /// <summary>
    /// Placeholder class for the LeadTime project.
    /// </summary>
    public class Class1
    {
    }
}

AuthType=OAuth;
Url=https://woodlandmillsqasandbox.crm3.dynamics.com;
AppId=<your-AAD-app-client-id>;
RedirectUri=app://<your-guid-or-use https://login.microsoftonline.com/common/oauth2/nativeclient>;
LoginPrompt=Auto;

Install-Package Microsoft.CrmSdk.CoreAssemblies -Version 9.0.2.60
Install-Package Microsoft.CrmSdk.Workflow      -Version 9.0.2.60   # if needed
Install-Package Microsoft.CrmSdk.Deployment    -Version 9.0.0.5    # if needed
Install-Package Microsoft.CrmSdk.XrmTooling.CoreAssembly -Version 9.0.0.5 # optional for tooling
