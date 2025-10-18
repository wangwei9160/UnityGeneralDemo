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

```Lua
-- Helloworld 举例
local Debug = CS.UnityEngine.Debug
Debug.Log("hello world")
```

1. Lua 访问全局变量CS
    
    LuaEnv 在初始化时的init_xlua脚本，设置了CS对应的元表和元方法

```lua
CS = CS or {}
setmetatable(CS, metatable)
```

2. __index 元方法递归查询并缓存使用到的类

```Lua
function metatable:__index(key)
    local fqn = rawget(self,'.fqn')
    fqn = ((fqn and fqn .. '.') or '') .. key

    local obj = import_type(fqn)
    -- ...
    return obj
end
```

3. 找到CS.UnityEngine.Debug类，将其存入Lua 注册表，在栈顶保存一个true or nil用于标记是否有元素，Lua侧从栈内读取

```CSharp
//  Lua 侧 xlua.import_type => C#侧 ImportType函数
importTypeFunction = new LuaCSFunction(StaticLuaCallbacks.ImportType);

// 根据C# 类型名字符串，在C#环境中查找并注册该类型，以便Lua侧可以直接使用它
[MonoPInvokeCallback(typeof(LuaCSFunction))]
public static int ImportType(RealStatePtr L) 
{ 
    /*...*/ 
    return 1; // 推入了一个值
}
```

假设栈顶为true，则代表可以找到
```Lua
local obj = import_type(fqn)
-- ...
if obj == true then
    return rawget(self, key)
end
```

## CSharp Call Lua

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
