# XLua

仅个人学习记录使用，非专业。

## Lua State

完整的Lua虚拟机实例，包含所有的运行环境、内存、全局变量、线程等。

```
rawL = LuaAPI.luaL_newstate();
```

### Lua Stack

Lua虚拟机与宿主语言进行交互的核心机制和数据通道；在XLua中起到了C#代码和底层Lua State之间的数据中转站的作用

#### 概念

##### 栈式虚拟机
Lua是基于寄存器和栈的虚拟机。它的栈是一个LIFO（后进先出）的数据结构，类似于C语言的调用栈，但主要用于数据传输和操作数存储。

##### 索引访问
正索引： 从1开始，表示栈底。例如，1是栈底的第一个元素。

负索引：从-1开始，表示栈顶。例如，-1是栈顶的元素。

#### 作用

在LuaEnv中，用于设置全局变量、注册函数、以及准备元表。

```

// 把C#的函数指针推入栈
LuaAPI.lua_pushstdcallcfunction(rawL, StaticLuaCallbacks.Print); // 栈顶：[-1] = C# Print Function

// 从栈顶取出函数，注册为Lua全局变量'print'
if (0 != LuaAPI.xlua_setglobal(rawL, "print")){}
```

##### C# Print函数

###### （函数调用，参数传递）
1. Lua 调用 C# 

Lua脚本中执行print(a,b) ，Lua虚拟机将控制权交给C#的Print函数。Lua会将参数a,b压入栈中。

2. C# 读取参数

C# 通过 ```int n = LuaAPI.lua_gettop(L);```确定栈中参数的数量```n```，通过正索引1到n访问参数

###### C# 被注册到Lua全局表的 Print函数

```
[MonoPInvokeCallback(typeof(LuaCSFunction))]
        internal static int Print(RealStatePtr L)
        {
            try
            {
                int n = LuaAPI.lua_gettop(L);
                string s = String.Empty;

                if (0 != LuaAPI.xlua_getglobal(L, "tostring"))
                {
                    return LuaAPI.luaL_error(L, "can not get tostring in print:");
                }

                for (int i = 1; i <= n; i++)
                {
                    LuaAPI.lua_pushvalue(L, -1);  /* function to be called */
                    LuaAPI.lua_pushvalue(L, i);   /* value to print */
                    if (0 != LuaAPI.lua_pcall(L, 1, 1, 0))
                    {
                        return LuaAPI.lua_error(L);
                    }
                    s += LuaAPI.lua_tostring(L, -1);

                    if (i != n) s += "\t";

                    LuaAPI.lua_pop(L, 1);  /* pop result */
                }
                UnityEngine.Debug.Log("LUA: " + s);
                return 0;
            }
            catch (System.Exception e)
            {
                return LuaAPI.luaL_error(L, "c# exception in print:" + e);
            }
        }
```


## LuaEnv

```csharp

// 获取Lua 注册表的索引
LuaIndexes.LUA_REGISTRYINDEX = LuaAPI.xlua_get_registry_index();

// 创建Lua State 
rawL = LuaAPI.luaL_newstate();

// 初始化基础库
// xlua库加载到Lua State中，下面提供给init_xlua使用
LuaAPI.luaopen_xlua(rawL); 
LuaAPI.luaopen_i64lib(rawL);

// 创建并注册 ObjectTranslator 【this ： LuaEnv ， rawL ： Lua State】
translator = new ObjectTranslator(this, rawL);

// Lua panic 回调 【Lua 虚拟机级别的错误处理函数】
LuaAPI.lua_atpanic(rawL, StaticLuaCallbacks.Panic);

// 初始化
DoString(init_xlua, "Init");
init_xlua = null;

// 注册全局 print
LuaAPI.lua_pushstdcallcfunction(rawL, StaticLuaCallbacks.Print);

// 在Lua 栈上创建一个新的Lua Table
LuaAPI.lua_newtable(rawL);
// 元表建 __index 推入Lua 栈
// 创建并且设置关键的Lua Table

// 1、Utils.LuaIndexsFieldName
// 2、Utils.LuaNewIndexsFieldName
// 3、Utils.LuaClassIndexsFieldName
// 4、Utils.LuaClassNewIndexsFieldName


// 将字符串 "xlua_csharp_namespace" 推入栈（用作注册表键）。
LuaAPI.xlua_pushasciistring(rawL, CSHARP_NAMESPACE);

// Lua全局表的CS模块存储到注册表中，
LuaAPI.lua_rawset(rawL, LuaIndexes.LUA_REGISTRYINDEX);


//将 Lua 全局的 CS 模块存储到注册表中，键名为 "CSHARP_NAMESPACE"。
LuaAPI.lua_rawset(rawL, LuaIndexes.LUA_REGISTRYINDEX);

// 从Lua State的全局环境中查找名为_G的变量。将查找到的_G table压入Lua栈的栈顶
LuaAPI.xlua_getglobal(rawL, "_G")

// 使用objectTranslator 将栈顶的Lua全局表转换为C#侧的LuaTable实例，赋值给_G 字段
translator.Get(rawL, -1, out _G);
// translator 创建了C# 侧的LuaTable 实例，这个LuaTable实例内部存储了一个指向Lua虚拟机中原始_G Tbale的稳定引用ID

```

### Xlua 初始化脚本 init_xlua

在Lua环境中配置基础的C# 访问机制、类型导入逻辑、Hotfix 功能，以及兼容性功能。将C# namespace和type 映射到Lua的Table中，使用元表实现按需加载。

####  初始化和变量

```lua
local metatable = {}
local rawget = rawget
local setmetatable = setmetatable
local import_type = xlua.import_type
local import_generic_type = xlua.import_generic_type
local load_assembly = xlua.load_assembly
```

#### metatable

1. lua访问呢一个C#命名空间或类型时触发，从当前table获取.fqn字段，然后拼接上当前的key，得到完整的命名空间路径，
    1. .fqn -> System； 
    2. key -> Collections； 
    3. ==> System.Collections
2. 尝试导入类型：import_type(fqn)
    1. 如果失败返回nil：可能只是一个中间命名空间，将新的fqn存储进去，并设置元表，继续访问下一层
    2. 如果成功：返回一个userdata代表这个C# 类型
3. 缓存并返回：通过 ```rawset(self, key, obj)``` 缓存到当前table。

```lua
function metatable:__index(key) 
    local fqn = rawget(self,'.fqn')
    fqn = ((fqn and fqn .. '.') or '') .. key

    local obj = import_type(fqn)

    if obj == nil then
        -- It might be an assembly, so we load it too.
        obj = { ['.fqn'] = fqn }
        setmetatable(obj, metatable)
    elseif obj == true then
        return rawget(self, key)
    end

    -- Cache this lookup
    rawset(self, key, obj)
    return obj
end
```

#### 限制

1. __newindex   防止用户对CS命名空间或以及解析的命名空间进行赋值
2. __call       将参数传递给xlua.import_generic_type，解析成C#侧的泛型类型

```Lua
function metatable:__newindex()
    error('No such type: ' .. rawget(self,'.fqn'), 2)
end

-- A non-type has been called; e.g. foo = System.Foo()
function metatable:__call(...)
    local n = select('#', ...)
    local fqn = rawget(self,'.fqn')
    if n > 0 then
        local gt = import_generic_type(fqn, ...)
        if gt then
            return rawget(CS, gt)
        end
    end
    error('No such type: ' .. fqn, 2)
end
```

#### 全局变量

设置CS全局变量、typeof、cast、setfenv、getfenv

```lua
CS = CS or {}
setmetatable(CS, metatable)

typeof = function(t) return t.UnderlyingSystemType end
cast = xlua.cast

function setfenv(fn, env)

function getfenv(fn)
```

#### Hotfix 机制

调用xlua.hotfix，将lua函数注入到指定的C#类(cs)的指定方法(filed)中

```lua
xlua.hotfix = function(cs, field, func)
    if func == nil then func = false end
    local tbl = (type(field) == 'table') and field or {[field] = func}
    for k, v in pairs(tbl) do
        local cflag = ''
        if k == '.ctor' then
            cflag = '_c'
            k = 'ctor'
        end
        local f = type(v) == 'function' and v or nil
        xlua.access(cs, cflag .. '__Hotfix0_'..k, f) -- at least one
        pcall(function()
            for i = 1, 99 do
                xlua.access(cs, cflag .. '__Hotfix'..i..'_'..k, f)
            end
        end)
    end
    xlua.private_accessible(cs)
end
xlua.getmetatable = function(cs)
    return xlua.metatable_operation(cs)
end
xlua.setmetatable = function(cs, mt)
    return xlua.metatable_operation(cs, mt)
end
xlua.setclass = function(parent, name, impl)
    impl.UnderlyingSystemType = parent[name].UnderlyingSystemType
    rawset(parent, name, impl)
end
```

#### base函数

Lua代码访问C#对象的基类方法。

```lua
local base_mt = {
    __index = function(t, k)
        local csobj = t['__csobj']
        local func = csobj['<>xLuaBaseProxy_'..k]
        return function(_, ...)
                return func(csobj, ...)
        end
    end
}
base = function(csobj)
    return setmetatable({__csobj = csobj}, base_mt)
end
```



## ObjectTranslator

### 像使用 Lua 对象一样使用 C# 对象，像使用 C# 对象一样使用 Lua 对象

ObjectTranslator 是 xLua 中 C# -> Lua 的桥梁，负责把 C# 对象/值 推入 Lua、把 Lua 值取回 C#、维护对象缓存与类型元表映射、生成/管理委托桥、处理结构体/枚举的打包。

封装了： 类型 id 映射、对象池、弱引用缓存、类型别名、定制 push/get/update、以及对反射/生成代码的延迟注册逻辑。

### ObjectTranslator 初始化

1. 初始化程序集列表

收集当前应用程序域中所有可用的C#程序集，提供Lua通过CS. 访问时进行类型查找

```CSharp
    assemblies = new List<Assembly>();

#if (UNITY_WSA && !ENABLE_IL2CPP) && !UNITY_EDITOR
    var assemblies_usorted = Utils.GetAssemblies();
#else
    assemblies.Add(Assembly.GetExecutingAssembly());
    var assemblies_usorted = AppDomain.CurrentDomain.GetAssemblies();
#endif
    addAssemblieByName(assemblies_usorted, "mscorlib,");
    addAssemblieByName(assemblies_usorted, "System,");
    addAssemblieByName(assemblies_usorted, "System.Core,");
    foreach (Assembly assembly in assemblies_usorted)
    {
        if (!assemblies.Contains(assembly))
        {
            assemblies.Add(assembly);
        }
    }
```

2. 初始化核心组件和缓存

```CSharp
this.luaEnv=luaenv;
// 类型转换器
objectCasters = new ObjectCasters(this);    
// 类型检查器
objectCheckers = new ObjectCheckers(this);
// C# 方法包装器缓存
methodWrapsCache = new MethodWrapsCache(this, objectCheckers, objectCasters);
// 由C# 静态方法桥接成的Lua C函数
metaFunctions=new StaticLuaCallbacks();
```

3. 准备导出C# 导出函数

将C# 的静态方法包装成LuaCSFunction委托。

```CSharp
importTypeFunction = new LuaCSFunction(StaticLuaCallbacks.ImportType);

// 根据C# 类型名字符串，在C#环境中查找并注册该类型，以便Lua侧可以直接使用它
[MonoPInvokeCallback(typeof(LuaCSFunction))]
public static int ImportType(RealStatePtr L)
{
    try
    {
        ObjectTranslator translator = ObjectTranslatorPool.Instance.Find(L);
        // 类型字符串
        string className = LuaAPI.lua_tostring(L, 1);
        // translator 利用.NET 反射或者配置列表来查找对应的Type对象
        Type type = translator.FindType(className);
        if (type != null)
        {
            if (translator.GetTypeId(L, type) >= 0)
            {
                // 找到则将true压入Lua Stack
                LuaAPI.lua_pushboolean(L, true);
            }
            else
            {
                return LuaAPI.luaL_error(L, "can not load type " + type);
            }
        }
        else
        {
            LuaAPI.lua_pushnil(L);
        }
        return 1;
    }
    catch (System.Exception e)
    {
        return LuaAPI.luaL_error(L, "c# exception in xlua.import_type:" + e);
    }
}

loadAssemblyFunction = new LuaCSFunction(StaticLuaCallbacks.LoadAssembly);
castFunction = new LuaCSFunction(StaticLuaCallbacks.Cast);
```

```CSharp
// LuaCSFunction ： 与Lua C API函数兼容，提供给Lua脚本直接调用
public delegate int lua_CSFunction(IntPtr L);
```

4. 创建C# 对象弱引用缓存

将__mode ， v 压入栈内，设置 __mode = v；这使得元表成为一个值弱引用元表

```lua
local myTable = {}
local mt = {
    __mode = "v"  -- 设置值为弱引用
}
setmetatable(myTable, mt)
```

ObjectTranslator： cacheRef
任何C# 对象被推入Lua时，都会在这个cacheRef引用的弱引用Table中注册一个值；
如果C# 侧的对象被.NET GC回收，lua侧的对应条目也会因为弱引用模式而被清理，避免内存泄漏
```CSharp
public int cacheRef; // -> 对应的是Lua内【C# 对象 弱引用缓存表】的索引 

// 初始化过程：
LuaAPI.lua_newtable(L);
LuaAPI.lua_newtable(L);
LuaAPI.xlua_pushasciistring(L, "__mode");
LuaAPI.xlua_pushasciistring(L, "v");
LuaAPI.lua_rawset(L, -3);
LuaAPI.lua_setmetatable(L, -2);
// 将table弹出栈，并将其引用存储到lua注册表中，返回其索引，赋值给C#的cacheRef
cacheRef = LuaAPI.luaL_ref(L, LuaIndexes.LUA_REGISTRYINDEX);
```

5. 初始化C#调用lua机制：调用内部方法，初始化C#侧用于调用Lua函数的机制

```CSharp
// 1. [CSharpCallLua] 特性标记所需的委托/接口
// 2. Xlua 在运行时收集这些类型，并为其唯一的函数签名动态生成高性能的C# 桥接代码
initCSharpCallLua();
```

### Get<T>方法

将Lua栈上指定索引位置的值，安全高效的转换为C#侧指定的类型


```CSharp
public void Get<T>(RealStatePtr L, int index, out T v)
{
    Func<RealStatePtr, int, T> get_func;
    // tryGetGetFuncByType ： Xlua 初始化时会注册一个委托

    if (tryGetGetFuncByType(typeof(T), out get_func))
    {
        v = get_func(L, index);
    }
    else
    {
        // 从Lua栈上获取C# 对象的userdata，并从ObjectTranslator的缓存中cacheRef找到对应的C#强引用。
        // 如果是表或函数，创建一个C#侧的包装对象，存储对应的Lua注册表引用ID
        // (objectCasters.GetCaster(typeof(object))(L, index, null));
        
        v = (T)GetObject(L, index, typeof(T));
    }
}
```

### GetTypeId 

为给定的C# Type对象获取一个唯一的整数 type_id ， 并在lua虚拟机内确保这个类型对应的元表已经被加载或创建，从而实现C# 类型在Lua侧的正确映射

```CSharp
public int GetTypeId(RealStatePtr L, Type type)
{
    bool isFirst;
    return getTypeId(L, type, out isFirst);
}
```

1. 如果已经被注册过，则直接返回对应的type_id

```CSharp
internal int getTypeId(RealStatePtr L, Type type, out bool is_first, LOGLEVEL log_level = LOGLEVEL.WARN)
{
    int type_id;
    is_first = false;
    if (!typeIdMap.TryGetValue(type, out type_id)) // no reference
    {
        // ...    
    }
    return type_id;
}
```

2. 如果是全新访问的，

```CSharp
LuaAPI.lua_pushvalue(L, -1);
// 保存到注册表，并且获得引用ID
type_id = LuaAPI.luaL_ref(L, LuaIndexes.LUA_REGISTRYINDEX);
LuaAPI.lua_pushnumber(L, type_id);
LuaAPI.xlua_rawseti(L, -2, 1);
LuaAPI.lua_pop(L, 1);

if (type.IsValueType())
{
    typeMap.Add(type_id, type);
}

// 存入 C# 缓存
typeIdMap.Add(type, type_id);
```

### 辅助工具 ObejctCasters

负责类型转换的组件，管理和执行将Lua栈上的值转换成C#指定类型的逻辑。初始化一些转换逻辑。

```CSharp
Dictionary<Type, ObjectCast> castersMap = new Dictionary<Type, ObjectCast>();

public ObjectCasters(ObjectTranslator translator)
{
    this.translator = translator;
    castersMap[typeof(char)] = charCaster;
    castersMap[typeof(sbyte)] = sbyteCaster;
    castersMap[typeof(byte)] = byteCaster;
    castersMap[typeof(short)] = shortCaster;
    castersMap[typeof(ushort)] = ushortCaster;
    castersMap[typeof(int)] = intCaster;
    castersMap[typeof(uint)] = uintCaster;
    castersMap[typeof(long)] = longCaster;
    castersMap[typeof(ulong)] = ulongCaster;
    castersMap[typeof(double)] = getDouble;
    castersMap[typeof(float)] = floatCaster;
    castersMap[typeof(decimal)] = decimalCaster;
    castersMap[typeof(bool)] = getBoolean;
    castersMap[typeof(string)] =  getString;
    castersMap[typeof(object)] = getObject;
    castersMap[typeof(byte[])] = getBytes;
    castersMap[typeof(IntPtr)] = getIntptr;
    //special type
    castersMap[typeof(LuaTable)] = getLuaTable;
    castersMap[typeof(LuaFunction)] = getLuaFunction;
}

// 一个泛型类型
public ObjectCast GetCaster(Type type)
{
    if (type.IsByRef) type = type.GetElementType();

    Type underlyingType = Nullable.GetUnderlyingType(type);
    if (underlyingType != null)
    {
        return genNullableCaster(GetCaster(underlyingType)); 
    }
    ObjectCast oc;
    if (!castersMap.TryGetValue(type, out oc))
    {
        oc = genCaster(type);
        castersMap.Add(type, oc);
    }
    return oc;
}
```

### 辅助工具 WeakReference

缓存和管理从Lua函数转换到C# 委托 或 C# 接口的桥接对象

1. 避免重复生成C# 委托包装器
2. 垃圾回收管理：允许C#委托被 \.NET GC回收，同时防止Lua对象被Lua GC意外回收
    C# 委托桥接对象本身是存储在 \.NET 托管堆上的C# 对象；如果用强引用，ObjectTranslator会一直持有这些C#委托实例的引用。只要LuaEnv存在，这些委托实例就永远不会被GC回收。

``` 
// ObjectTranslator 类中持有一个Dictionary
Dictionary<int, WeakReference> delegate_bridges = new Dictionary<int, WeakReference>(); 
```