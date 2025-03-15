using XLua;
using System;
using UnityEngine;
using System.IO;

[Hotfix]
[LuaCallCSharp]
public class LuaManager : Singleton<LuaManager>
{
    public  const string luaScriptsFolder = "../Lua";
    private const string gameMainScriptName = "main";
    private const string hotfixScriptName = "Hotfix";

    private Action<float> _luaUpdate = null;

    private static string _luaScriptsFullPath;

    private LuaEnv _luaEnv;

    public LuaEnv luaEnv
    {
        get { return _luaEnv; }
    }

    void Start()
    {
        _luaScriptsFullPath = Path.Combine(Application.dataPath, luaScriptsFolder);
        _luaEnv = new LuaEnv();
        luaEnv.AddLoader(MyLoader);
        luaEnv.DoString("require('main')");
        LuaFileWatcher.CreateLuaFileWatcher(_luaEnv);
    }

    private void Update()
    {
        if (_luaEnv != null)
        {
            _luaEnv.Tick();
        }

        if (_luaUpdate != null)
        {
            _luaUpdate(Time.deltaTime);
        }
    }

    void OnDestroy()
    {
        if (_luaEnv != null)
        {
            _luaEnv.Dispose();
            _luaEnv = null;
        }
    }

    private byte[] MyLoader(ref string filepath)
    {
        filepath = filepath.Replace("." , "/") + ".lua";
        string path = Path.Combine(_luaScriptsFullPath, filepath);
        return FileOperation.SafeReadAllBytes(path);
    }

}
