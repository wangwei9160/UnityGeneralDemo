using System;
using UnityEngine;
using XLua;
using XLua.LuaDLL;

namespace XLuaTest
{
    public class CallLuaTest : MonoBehaviour
    {
        [CSharpCallLua]
        public delegate void funcTest(string str);

        private string script = @"
                FuncTest = function(str)
                    print('FuncTest:' .. str)
                end
	        ";
        private LuaEnv luaenv;
        void Start()
        {
            luaenv = new LuaEnv();
            Test(luaenv);
            // GC.WaitForPendingFinalizers();
            // luaenv.Dispose();
        }

        void Test(LuaEnv luaenv)
        {
            luaenv.DoString(script);
            funcTest func_test = luaenv.Global.Get<funcTest>("FuncTest");
            func_test("hello funcTest");
            func_test("你好 funcTest");
        }

        void OnDisable()
        {
            luaenv.Dispose();
        }


        // Update is called once per frame
        void Update()
        {

        }
    }
}