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
        [CSharpCallLua]
        public delegate int GetFunc(int x);

        private string script = @"
                ClassA = {
                    printA = function(self)
                        print('ClassA printA')
                    end
                }
                GetFunc = function(x)
                    return x + 1
                end

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
            GetFunc get_func_test = luaenv.Global.Get<GetFunc>("GetFunc");
            Debug.Log("GetFunc result:" + get_func_test(10));
        }

        void OnDisable()
        {
            luaenv.Dispose();
        }
    }
}