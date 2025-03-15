using FairyGUI;
using XLua;

public static class LuaHelper
{
    public static GObject LoadUI(string pkgName , string resName){
        string packagePath = "Assets/ResourcesAssets/" + pkgName;
        UIPackage.AddPackage(packagePath);
        GObject ui = UIPackage.CreateObject(pkgName, resName);
        GRoot.inst.AddChild(ui);
        return ui;
    }
}
