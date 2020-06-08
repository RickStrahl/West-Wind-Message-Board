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
    
    <link href="../lib/bootstrap/dist/css/bootstrap.bundle.min.css" rel="stylesheet" />    
    <link href="../lib/fontawesome/css/all.min.css" rel="stylesheet" />
    <link href="../css/application.css" rel="stylesheet" />      
    <script src="../lib/jquery/dist/jquery.min.js"></script>
    <style>
        .row li {
            margin-left: -15px;    
            margin-top: 5px;                  
        }
    </style>  
</head>
<body>
<div class="flex-master">
   
    <div class="banner">
         <!-- Icon and Company Logo -->
            <img class="title-bar-icon" src="../images/icon.png" />
            <div class="title-bar no-slide-menu">
                <a href="../">                    
                    <div style="float: left; margin: 4px 45px; line-height: 1.0">
                        <i style="color: #0092d0; font-size: 0.975em; font-weight: bold;">West Wind</i><br />
                        <i style="color: whitesmoke; font-size: 1.7em; font-weight: bold;">Message Board</i>
                    </div>
                </a>
            </div>

        <nav class="banner-menu-top float-right">
            <a href="http://west-wind.com/webconnection/docs/" 
                target="top"
                class="hidable">
                <i class="fa fa-book"></i>
                Documentation
            </a>
            <a href="admin_wwt.htm">
                <i class="fa fa-edit"></i>
                wwThreads
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

        <%  
          string user = Request.ServerVariables["AUTH_USER"];
          string remoteIp = Request.ServerVariables["REMOTE_ADDR"];
          string localIp = Request.ServerVariables["LOCAL_ADDR"];           
          if (string.IsNullOrEmpty(user))
          { 
        %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-triangle" style="font-size: 1.1em; color: firebrick;">
            </i>
            <b>Security Warning:</b> You are accessing this request unauthenticated!
            <div style="border-top: solid 1px silver; padding-top: 5px; margin-top: 5px; ">
                <p>
                    You should enable authentication and remove anonymous access to this page or folder.
                    <small><a href="https://west-wind.com/webconnection/docs/_00716R7OG.HTM">more info...</a></small>
                </p>
                <% if(localIp != remoteIp)  { %>
                <p style="color:red; font-weight: bold">
                    You are not allowed to access this page without authentication from a remote address.
                    Aborting page display...
                </p>
                <% } else { %>
                <p style="color:red; font-weight: bold">
                    NOTE: You are allowed to access this page, because you are accessing it from the
                    local machine, but it won't work from a remote machine.
                </p>   
                <% } %>
            </div>
        </div>
        <% 

            if(localIp != remoteIp)
            {
                Response.End();
            }            
        } 
        %>


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
                        <a href="Reindex.wwd"><b>Pack and Reindex Web Connection Demo Files</b></a>
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
                        <a href="UpdateExe.wc" class="btn btn-sm btn-primary" style="width: 140px;">
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
    </div> <!-- end #MainView -->
    

    <footer>
        <a href="http://www.west-wind.com/" class="float-right" >
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