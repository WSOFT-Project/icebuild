using Alice.IO;
using Alice.Packaging;
using Alice.Environment;
using Alice.Interpreter;

namespace WSOFT.CodeAnalysis.IceBuild;

protected void progress(delegate task, string message)
{
    if(!silent)
    {
        write(indentChar.Repeat(indentLevel));
        write($"{message}.");
        bool complete = false;
        var thread = ()=>{
            task.Invoke();
            complete = true;
        }
        thread.BeginInvoke();
        while(!complete)
        {
            write(".");
            delay(500);
        }
        print("success");
    }
}

protected variable getParameter(string n, string name)
{
    var result = [];
    number ind = 0;
    while(true)
    {
        ind = args.IndexOf($"-{n}", ind);
        if(ind < 0)
        {
            break;
        }
        ind++;
        if(args.Length > ind)
        {
            var next = args[ind];
            if(next.StartsWith("-"))
            {
                result.add("");
            }
            else
            {
                result.add(next);
            }
        }
        else
        {
            result.add("");
            break;
        }
    }
    ind = 0;
    while(true)
    {
        ind = args.IndexOf($"--{name}", ind);
        if(ind < 0)
        {
            break;
        }
        ind++;
        if(args.Length > ind)
        {
            var next = args[ind];
            if(next.StartsWith("-"))
            {
                result.add("");
            }
            else
            {
                result.add(next);
            }
        }
        else
        {
            result.add("");
            break;
        }
    }
    return result;
}

protected bool existsParameter(string n, string name)
{
    return getParameter(n, name).Length > 0;
}

protected number indentLevel = 0;
protected string indentChar = " ";

protected void showLogo()
{
    if(!no_logo)
    {
        showLog("IceBuild Version 1.0");  
        showLog("Copylight (c) 2024 WSOFT All rights reserved.");
        showLog("");
    }
    
}

protected void output(string message, bool need)
{
    if(need || !silent)
    {
        print(indentChar.Repeat(indentLevel) + message);
    }
}

protected void showLog(string message)
{
    output(message, false);
}

protected void showError(string message)
{
    output($"[\e[31mERROR\e[37m] {message}", true);
    env_exit(1);
}

protected void showWarning(string message)
{
    output($"[\e[33mWARNING\e[37m] {message}", warning_as_error);
    if(warning_as_error)
    {
        showError("The warning was treated as an error.");
    }
}

protected void showInfo(string message)
{
    output($"[\e[34mINFO\e[37m] {message}", false);
}

protected string getOrDefault(string n, string name, string default)
{
    var ary = getParameter(n,name);
    foreach(string s in ary)
    {
        if(!s.IsNullOrEmpty())
        {
            return s;
        }
    }
    return default;
}

protected void checkManifest(string filename)
{
    indentLevel++;
    if(!file_exists(filename))
    {
        showError("manifest.xml does not exists.");
    }
    showInfo("manifest.xml found.");
    string xml = file_read_text(filename);
    var mData = package_getManifestFromXml(xml);

    if(mData == null)
    {
        showError("manifest.xml incorrect format.");
    }
    showLog("");
    showLog("* Package Info *");
    indentLevel++;
    showLog($"> Name: {mData.Name}");
    showLog($"> Version: {mData.Version}");
    showLog($"> Publisher: {mData.Publisher}");

    if(mData.UseInlineScript)
    {
        showLog($"> Src: Inline");
        indentLevel--;
    }else
    {

    if(file_exists(path_combine(source, mData.ScriptPath)))
    {
        showLog($"> Src: {mData.ScriptPath}");
        indentLevel--;
        showInfo("Script detected");
    }
    else
    {
        indentLevel--;
        showError("Script not found");
    }
    }

    indentLevel--;
}

protected string compressDirectory(string dirname)
{
    string tmp = path_get_tempFileName();
    file_delete(tmp);
    zip_CreateFromDirectory(dirname,tmp);
    return tmp;
}

protected void createPackage(string from, string to, ccd)
{
    package_createFromZipFile(from,to,ccd);
}
