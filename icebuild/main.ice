using Alice.IO;
using Alice.Packaging;
using Alice.Environment;
using Alice.Interpreter;

include("lib.ice");

namespace WSOFT.CodeAnalysis.IceBuild;

array args = env_commandLineArgs();
if(args.Length < 1)
{
    showError("Source directory not specified.");
}

bool warning_as_error = existsParameter("we","warn-as-error");
bool no_logo = existsParameter("nl","nologo");
bool silent = existsParameter("s","silent");

try
{
    showLogo();
    string source = path_get_fullPath(args.first);
    string target = getOrDefault("out","target", source + ".ice");
    string manifest = path_combine(source, "manifest.xml");

    showLog("Building AlicePackage");
    indentLevel++;
    showLog($"from: {source}");
    showLog($"  to: {target}");
    indentLevel--;

    if(!directory_exists(source))
    {
        showError("Source directory does not exist.");
    }
    if(file_exists(target))
    {
        showWarning("Target file already exists.");
    }

    showLog("");
    bytes? cc = null;
    var gp = getParameter("c","control");
    if(gp.Length > 0)
    {
        if(!file_exists(gp.first))
        {
            showError("Control code file not exists.");
        }
        showInfo("Control code detected.");
        cc = file_read_data(gp.first);
    }

    showLog("");
    showLog("1/4 Reading package manifest.");
    checkManifest(manifest);

    showLog("");
    string archive = "";
    progress(()=>{
        archive = compressDirectory(source);
    }, "2/4 Compressing directory");
    indentLevel++;
    showInfo($"Output -> {archive}");
    indentLevel--;

    showLog("");
    progress(()=>{
        createPackage(archive, target, cc);
    }, "3/4 Creating package");
    indentLevel++;
    showInfo($"Output -> {target}");
    indentLevel--;

    showLog("");
    progress(()=>{
        file_delete(archive);
    }, "4/4 Cleaning TemporaryFile");
    indentLevel++;
    showInfo($"Removed -> {archive}");
    indentLevel--;
    showLog("");
    showLog("Successfully built.");
}
catch(e)
{
    showError($"Unhandled error occurred.{env_newline}{e.message}");
}

