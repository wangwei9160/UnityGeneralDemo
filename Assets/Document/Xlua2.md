# XLua C# 和 Lua 的交互

## Lua C# 通信

XLua 是基于 Lua C API 进行封装和交互的。

```CSharp 
using LuaCSFunction = XLua.LuaDLL.lua_CSFunction;

// C函数必须return 一个整数，表示它向栈中推送了多少个返回值
[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate int lua_CSFunction(IntPtr L);
```

## Lua Call CSharp

### 0. hello world

```Lua
-- Helloworld 举例
local Debug = CS.UnityEngine.Debug  -- 持有对象
Debug.Log("hello world")            -- 调用函数
```

### 1. Lua 访问全局变量CS
    
    LuaEnv 在初始化时的init_xlua脚本，设置了CS对应的元表和元方法

```lua
CS = CS or {}
setmetatable(CS, metatable)
```

### 2. __index 元方法递归查询并缓存使用到的类

函数负责将 Lua 的点号访问 (CS.A.B) 映射到 C# 的全限定名 (FQN) 查找。

```Lua
function metatable:__index(key)
    local fqn = rawget(self,'.fqn')
    fqn = ((fqn and fqn .. '.') or '') .. key

    local obj = import_type(fqn)
    -- ...
    return obj
end
```

### 3. 找到CS.UnityEngine.Debug类，将其存入Lua 注册表，在栈顶保存一个true or nil用于标记是否有元素，Lua侧从栈内读取

```CSharp
//  Lua 侧 xlua.import_type => C#侧 ImportType函数
importTypeFunction = new LuaCSFunction(StaticLuaCallbacks.ImportType);

// 根据C# 类型名字符串，在C#环境中查找并注册该类型，以便Lua侧可以直接使用它
[MonoPInvokeCallback(typeof(LuaCSFunction))]
public static int ImportType(RealStatePtr L) 
{ 
    /* ... */
    Type type = translator.FindType(className); // C# 环境内查找
    /* ... */ 
    if (translator.GetTypeId(L, type) >= 0)  // 检测是否已经在注册表内
    /* ... */
    return 1; // 推入了一个值
}

internal Type FindType(string className, bool isQualifiedName = false) {/* ... */}

internal int getTypeId(RealStatePtr L, Type type, out bool is_first, LOGLEVEL log_level = LOGLEVEL.WARN) 
{
    /* ... */
    TryDelayWrapLoader(); // 保证这个类正确加载
    /* ... */
}
```

### 4. 缓存与调用

假设栈顶为true，则代表可以找到
```Lua
local obj = import_type(fqn)
-- ...
if obj == true then
    return rawget(self, key)
end
```

### 5. 函数调用 Debug.Log

C# 侧 UnityEngineDebugWrap类，初始化注册了函数```Utils.RegisterFunc(L, Utils.CLS_IDX, "Log", _m_Log_xlua_st_);```; 调用Log时，实际调用```_m_Log_xlua_st_```。

```CSharp
public static void RegisterFunc(RealStatePtr L, int idx, string name, LuaCSFunction func)
{
    idx = abs_idx(LuaAPI.lua_gettop(L), idx);
    LuaAPI.xlua_pushasciistring(L, name);
    LuaAPI.lua_pushstdcallcfunction(L, func);
    LuaAPI.lua_rawset(L, idx);
}
```

Lua侧 访问Debug Table的Log方法 ==> 找到Lua C函数 _m_Log_xlua_st_，将参数```"hello world"```压入Lua栈，调用C#导出的```_m_Log_xlua_st_```函数

### 6. C# 侧 _m_Log_xlua_st_

```CSharp
ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
    
int gen_param_count = LuaAPI.lua_gettop(L);

if(gen_param_count == 1&& translator.Assignable<object>(L, 1)) 
{
    object _message = translator.GetObject(L, 1, typeof(object));
    
    UnityEngine.Debug.Log( _message ); // C# Log方法
    
    return 0;
}
```


## CSharp Call Lua

### 0. 

LuaEnv.Global.Get\<T\>： 从全局表中获取一个指定类型的数据，参数为 string 类型标识在 lua 中的字段名。Xlua 根据结构来映射。

```csharp
private LuaTable _G;
public LuaTable Global
{
    get
    {
        return _G;
    }
}
```
