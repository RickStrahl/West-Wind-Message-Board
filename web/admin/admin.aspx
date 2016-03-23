<%@Page language="C#" Trace="false" %>
<!DOCTYPE html>
<html>
<head>
    <title>Administration - West Wind Web Connection</title>

    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <meta name="description" content="" />

    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="black" />
    <link rel="apple-touch-icon" href="touch-icon.png" />
    
    <link href="../bower_components/bootstrap/dist/css/bootstrap.min.css" rel="stylesheet" />    
    <link href="../bower_components/font-awesome/css/font-awesome.min.css" rel="stylesheet" />
    <link href="../css/application.css" rel="stylesheet" />      
    <script src="../bower_components/jquery/dist/jquery.min.js"></script>
    <style>
        .row li {
            margin-left: -15px;    
            margin-top: 5px;                  
        }
    </style>  
</head>


<%
  this.Physical = Request.ServerVariables["PATH_TRANSLATED"];
  if (string.IsNullOrEmpty(this.Physical))
       return;
  
  this.Physical = System.IO.Path.GetDirectoryName(this.Physical);    

  // allow items with exe prefix 
  this.Show = Request.Form["exeprefix"];

  if (string.IsNullOrEmpty(this.Show))
  {
    string exefile = GetProfileString("wwcgi", "exefile");
    if (System.IO.File.Exists(exefile))
        this.Show = System.IO.Path.GetFileNameWithoutExtension(exefile);
  }

  if (string.IsNullOrEmpty(this.Show))
     this.Show = "wc";
%>
<body>
<div class="flex-master">
   
    <div class="banner">
        <a class="slide-menu-toggle-open no-slide-menu"
           title="More Samples">
            <i class="fa fa-bars"></i>
        </a>


        <div class="title-bar no-slide-menu" >
            <a>
                <img src="../images/Icon.png"
                     style="height: 45px; float: left"/>
                <div style="float: left; margin: 4px 5px; line-height: 1.0">
                    <i style="color: #0092d0; font-size: 0.9em; font-weight: bold;">West Wind</i><br/>
                    <i style="color: whitesmoke; font-size: 1.65em; font-weight: bold;">Web Connection</i>
                </div>
            </a>
        </div>

        <nav class="banner-menu-top pull-right">
            <a href="http://west-wind.com/webconnection/docs/" 
                target="top"
                class="hidable">
                <i class="fa fa-book"></i>
                Documentation
            </a>
            <a href="../">
                <i class="fa fa-home"></i>
                Home
            </a>
        </nav>
    </div>


<div id="MainView">
    <div style="margin: 10px 20px;">
        <div class="page-header-text">
            <i class="fa fa-gears"></i>
            Web Connection Server Maintenance
        </div>

        <%  string user = Request.ServerVariables["AUTH_USER"]; %>


        <%if (string.IsNullOrEmpty(user))
          { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-triangle" style="font-size: 1.1em; color: firebrick;">
            </i>
            <b>Security Warning:</b> You are accessing this request unauthenticated!
            <div style="border-top: solid 1px silver; padding-top: 5px; margin-top: 5px; ">
                You should enable authentication and remove anonymous access to this page or folder.
            </div>
        </div>
        <% } %>


        <div class="row" >
            <div class="col-sm-6" style="margin-bottom: 30px;" >
                

                <h4>Log Files</h4>                
                <ul>
                    <li><b><a href="wc.wc?wwmaint~showlog">Web Connection Server Request Log</a></b></li>
                    <li><b><a href="wc.wc?wwmaint~showlog~Error">Web Connection Server Error Log</a></b></li>
                    <li><b><a href="wc.wc?wwMaint~ClearLog~NoBackup">Clear Server Log to today's date</a></b></li>
                    <li><b><a href="wc.wc?wwMaint~wcDLLErrorLog">Web Connection Module Error Log</a></b></li>
                </ul>
                
                <h4>Server Settings</h4>
                <ul>                    
                    <li><b><a href="wc.wc?wwmaint~ShowStatus">Web Connection Server Settings</a></b></li>
                    <li><b><a href="wc.wc?wwMaint~EditConfig">Edit Configuration Files</a></b></li>
                </ul>

                <h4>Server Resources</h4>
                <ul>
                    <li>
                        <a href="wc.wc?wwMaint~ReindexSystemFiles"><b>Pack and Reindex wwSession Table</b></a></li>
                    <li>
                        <a href="wc.wc?wwDemo~Reindex"><b>Pack and Reindex Web Connection Demo Files</b></a>
                    </li>                            
                    <li>
                        <b>Script Mode:</b>
                        <small>
                            <a href="wc.wc?wwMaint~ScriptMode~Interpreted">Interpreted</a>&nbsp; 
                            <a href="wc.wc?wwMaint~ScriptMode~PreCompiled">PreCompiled</a>
                        </small>
                        </li>
                        <li>
                            <form method="POST" action="wc.wc?wwmaint~CompileWCS">                    
                                <input type="text" 
                                      name="txtFileName" 
                                    class="form-control"
                                    value="<%= Request.PhysicalApplicationPath %>*.wcs" style="width: 330px; margin-bottom: 5px;">                                
                                 <button type="submit" name="btnSubmit" class="btn btn-primary">
                                     <i class="fa fa-code"></i>
                                     Compile WCS Script Pages
                                 </button>
                            </form>                                                       
                        </li>
                
        </ul>

            </div> <!-- end col 1 -->



            <div class="col-sm-6">
                
                <h4>Module Administration</h4> 
                <ul>
                 <li>                    
                    <b><a href="ModuleAdministration.wc">Web Connection Module Administration</a></b><br>
                    <small>Shows the status of the underlying .NET or ISAPI&nbsp; DLL connector flags, lets you switch from File to COM operation, shows
                    all instances of the server loaded under Com and the current state of the HoldRequests
                    flag.</small>
                </li>
                </ul>
                
                <h4>Server Hotswapping</h4>
                <ul>
                    <li> <b>Upload new Web Connection Server</b><br />
                        <p class="small">
                            Upload a new Web Connection server EXE to the filename specified in the <b>UpdateExe</b>
                            configuration setting.
                        </p>

                        <style>
                            /* Container*/
                            .fileUpload {
                                position: relative;
                                overflow: hidden;
                            }
                            /* hide the actual file upload control by making it invisible */
                            .fileUpload input.upload {
                                position: absolute;
                                top: 0;
                                right: 0;
                                margin: 0;
                                padding: 0;
                                font-size: 20px;
                                cursor: pointer;
                                opacity: 0;
                                filter: alpha(opacity=0);
                            }
                        </style>

                        <form action="Uploadexe.wc" method="POST" enctype="multipart/form-data">
                            <div class="fileUpload btn btn-sm btn-primary stackable" style="width: 220px;">
                                <span>
                                    <i class="fa fa-upload"></i>
                                    Upload Server Exe (.NET Handler)
                                </span>
                                <input type="file" id="file" name="file" class="upload" />
                            </div>
                            
                            <button id="UploadButton" type="submit" class="visually-hidden" >                                                                
                                Upload (.NET Module)
                            </button>                            
                            <script>
                                document.getElementById("file").onchange = function () {                                    
                                    $("#UploadButton").trigger("click");
                                };
                            </script>
                        </form>
                        
                       
                        <form action="wc.wc?wwMaint~FileUpload" method="POST" enctype="multipart/form-data" style="margin-top: 5px;">
                            <div class="fileUpload btn btn-sm btn-primary stackable" style="width: 220px;">
                                <span>
                                    <i class="fa fa-upload"></i>
                                    Upload Server Exe (ISAPI Handler)
                                </span>
                                <input type="file" id="file" name="file" class="upload" />
                            </div>
                            
                            <button id="UploadButton" type="submit" class="visually-hidden" >                                
                               Upload
                            </button>                            
                            <script>
                                document.getElementById("file").onchange = function () {                                    
                                    $("#UploadButton").trigger("click");
                                };
                            </script>
                        </form>

                        <p class="small" style="margin-top: 12px;">
                            Once uploaded you can hotswap the uploaded server exe
                            by copying the <b>UpdateExe</b> to the <b>ExeFile</b>.
                        </p>
                        <a href="wc.wc?_maintain~UpdateExe" class="btn btn-sm btn-primary" style="width: 140px;">
                            <i class="fa fa-refresh"></i>
                            Swap Server Exe
                        </a>
                    </li>                                  
                
                    <li>
                        <b><a href="wc.wc?wwMaint~RebootMachine~&RestartOnly=yes"> Restart IIS</a> | <a href="wc.wc?wwMaint~RebootMachine">Reboot Machine</a></b>                        
                        </br>
                        <i><small>Make sure your server can fully restart without manual interaction or logons.</small></i>
                    </li>
                
                </ul>
            </div> <!-- end col 2 --> 
        </div>

        <div class="well well-sm">
            <form action='' method='POST'>
                Exe file starts with: 
            <input type='text' id='exeprefix' name='exeprefix' value='<%= this.Show %>' class="input-sm" />
                <button type='submit' class="btn btn-default btn-sm">
                    <i class="fa fa-refresh"></i>
                    Refresh
                </button>
            </form>
        </div>


        <table class="table table-condensed table-responsive table-striped" >
            <tr>
                <th>Process Id</th>
                <th>Process Name</th>
                <th>Working Set</th>
                <th>Action</th>
            </tr>
            <%      
                System.Diagnostics.Process[] processes = this.GetProcesses();
                foreach (System.Diagnostics.Process process in processes)
                {
            %>
            <tr>
                <td><%= process.Id%></td>
                <td><%= process.ProcessName%></td>
                <td><%= (process.WorkingSet / 1000000.00).ToString("n1") %> mb</td>
                <td><a href="admin.aspx?ProcessId=<%= process.Id %>" class="hoverbutton">
                    <i class="fa fa-remove" style="color: firebrick;"></i> 
                    Kill
                </td>
            </tr>
            <%
    }
            %>            
        </table>

    </div> <!-- end #MainView -->
    

    <footer>
        <a href="http://www.west-wind.com/" class="pull-right" >
            <img src="../images/WestwindText.png" />
        </a>
        <small>&copy; Westwind Technologies, 1995-<%= DateTime.Now.Year %></small>
    </footer>
   
</div>

    <script type="text/javascript">
        function updateWebResources() {
            var str = "This operation updates Web resources from the Web Connection install folder and overwrites existing default scripts, images and css files.\r\n\r\n" +
                      "Are you sure you want to update Web Resources?"
            return confirm(str);
        }
    </script>


</body>
</html>

    
<script runat="server">
        [System.Runtime.InteropServices.DllImport("kernel32")]
        private static extern int GetPrivateProfileString(string section,
                 string key,string def, StringBuilder retVal,
                 int size,string filePath);

        private string GetProfileString(string section, string key)
        {
            string filename = Server.MapPath("~/") + "wc.ini";
            if (!System.IO.File.Exists(filename))
            {
                filename = Server.MapPath("~/bin/") + "wc.ini";
                if (!System.IO.File.Exists(filename))
                    return string.Empty;
            }
            
            return GetProfileString(filename,section,key);
        }
        private string GetProfileString(string fileName, string section, string key)
        {
            StringBuilder sb = new StringBuilder(255);
            int result = GetPrivateProfileString(section, key, string.Empty, sb, 255, fileName);

            return sb.ToString();                           
        }
        System.Diagnostics.Process[] GetProcesses()
        {
            // get all processes
            System.Diagnostics.Process[] processes = null;
            try
            {
                processes = System.Diagnostics.Process.GetProcesses();
            }
            catch
            {
                return null;
            }

           if (processes == null)
            return null;
            
            string ProcessId = Request.QueryString["ProcessID"];
            if (ProcessId == null)
                ProcessId = string.Empty;
            
            int procId = 0;
            int.TryParse(ProcessId, out procId);

            System.Collections.Generic.List<System.Diagnostics.Process> processList = new System.Collections.Generic.List<System.Diagnostics.Process>();
            foreach (System.Diagnostics.Process process in processes)
            {
                if (procId > 0 && process.Id == procId)
                {
                    process.Kill();
                    continue;
                }
                else
                {
                    string procName = process.ProcessName.ToLower();
                    if (procName == "inetinfo" || procName == "w3wp" || procName.StartsWith(this.Show) || procName.StartsWith("vfp"))
                    {
                        processList.Add(process);
                    }
                }
            }
            
            return processList.ToArray();
        }
        // The prefix of items to show (typically an exe filename)
        private string Show = string.Empty;
        private string Physical = null;
</script>
